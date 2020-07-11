##############################################################################################################
import re
import sys
import table

##############################################################################################################
# Support Classes
class Symbol:

    def __init__(self):
        self.labelDefs = {}
        self.expr = []

class Code:

    def __init__(self):
        self.data = []
        self.address = 0
        self.label = ""

##############################################################################################################
# File reading functions

def read(name):
    # This function reads in lines from the asm file
    # It processes them and puts them into the form:
    # [[Line_number, Program_Counter] [body] [comment]]
    # Line_number corrisponds to the line on the 
    # source code. the Program_Counter is incremented
    # every time there is a non-empty line (even a comment
    # counts as non empty). Note that two consecutive PC
    # locations do NOT nessisarily corrispond to two
    # consecutive address locations

    # [[Line_number, Program_Counter] [body] 'comment']
    
    file = open(name, 'r')
    lines = []
    lineNumber = 0
    pc = 0
    
    for lineNumber, line in enumerate(file, start = 1):
        line = line.strip()
        line = line.upper()
        if(line):
            block = []
            rest = [] 												   # The input line without the comment
            comment = ''
            commentIndex = line.find(";")
            if(commentIndex != -1):
                comment = line[commentIndex:]
                rest = line[:commentIndex].strip()
            else:
                rest = line

            block.append([lineNumber, pc])
            if(rest): 												   # If we have code after we strip any comment out
                split_rest = re.split(r'([-+,\s]\s*)', rest)
                split_rest = [word for word in split_rest if not re.match(r'^\s*$',word)]
                split_rest = list(filter(None, split_rest))
                block.append(split_rest)
            else:
                block.append([])
            block.append(comment)
            lines.append(block)
            pc += 1
            
    file.close()
    return lines
##############################################################################################################
def lexer(lines):
    tokens = []
    code_lines = [x for x in lines if len(x[1])]                # code_lines only includes lines with code,
    for line in code_lines:                                     # so if a line only has comments, then
        tl = []                                                 # then it's out
        for word in line[1]:
            word = word.strip()
            if word in table.mnm_r_i:
                tl.append(["<mnm_r_i>", word])
            elif word in table.mnm_r_l:
                tl.append(["<mnm_r_l>", word])
            elif word in table.mnm_r_r:
                tl.append(["<mnm_r_r>", word])
            elif word in table.mnm_r:
                tl.append(["<mnm_r>", word])
            elif word in table.mnm_r_rp:
                tl.append(["<mnm_r_rp>", word])
            elif word in table.mnm_rp:
                tl.append(["<mnm_rp>", word])
            elif word in table.mnm_a:
                tl.append(["<mnm_a>", word])
            elif word in table.mnm_n:
                tl.append(["<mnm_n>", word])
            elif word in table.mnm_m:
                tl.append(["<mnm_m>", word])
            elif word == ",":
                tl.append(["<comma>", word])
            elif word == "+":
                tl.append(["<plus>", word])
            elif word == "-":
                tl.append(["<minus>", word])
            elif re.match(r'^R((1*)[02468])|16$',word):
                tl.append(["<reg_even>", word])
            elif re.match(r'^R((1*)[13579])|15$',word):
                tl.append(["<reg_odd>", word])
            elif re.match(r'^.+:$',word):
                tl.append(["<lbl_def>", word])
            elif(re.match(r'^(0X)[0-9A-F]+$', word)):
                tl.append(["<hex_num>", word])
            elif(re.match(r'^[0-9]+$', word)):
                tl.append(["<dec_num>", word])
            elif(re.match(r'^(0B)[0-1]+$', word)):
                tl.append(["<bin_num>", word])    
            elif(re.match(r'^[A-Z_]+[A-Z_]*$', word)):
                tl.append(["<symbol>", word])
            elif word == "$":
                tl.append(["<lc>", word])
            else:
                tl.append(["<idk_man>", word])
                return [0 , 0]

        tokens.append(tl)

    return [code_lines, tokens]
##############################################################################################################
def error(message, line):
    print("Error at line " + str(line[0][0]) + ": " + message)
##############################################################################################################
def parse_lbl_def(tokens, symbols, code, line):
    er = ["<error>"]
    if not tokens:
        return 0
    if(tokens[0][0] == "<lbl_def>"):
        lbl = tokens[0][1]
        if lbl[:-1] in symbols.labelDefs:
            error("Label already in use!",line)
            return er
        elif lbl[:-1] in table.reserved:
            error("Label cannot be keyword!",line)
            return er
        elif re.match(r'^(0X)[0-9A-F]+$',lbl[:-1] or
             re.match(r'^[0-9]+$',lbl[:-1]) or
             re.match(r'^(0B)[0-1]+$')):
            error("Label cannot be number!",line)
            return er
    else:
        return 0

##############################################################################################################
# Grammar:
#
# <line> ::= <lbl_def> [<drct>] [<code>]
#          | <drct> [<code>]
#          | <code>
#
# <code> ::= <mnm_r_i> <reg> "," <expr>
#          | <mnm_r_l> <reg> "," <expr>
#          | <mnm_r_r> <reg> "," <reg>
#          | <mnm_r> <reg>
#          | <mnm_r_rp> <reg> "," <reg_even>
#          | <mnm_rp> <reg_even>
#          | <mnm_a> <expr>
#          | <mnm_n>
#          | <mnm_m> <expr>
#
# <reg>  ::= <reg_even>
#          | <reg_odd>
#
# <expr> ::= [ (<plus> | <minus>) ] <numb> { (<plus> | <minus>) <numb> }
#
# <drct> ::= <drct_1> <expr>
#          | <drct_p> <expr> { ","  <expr> }
#
# <numb> ::= <hex_num> | <dec_num> | <bin_num> | <symbol> | <lc>
##############################################################################################################
def parse_line():
    data = ["<line>"]
    er = ["<error>"]
    if(len(tokens) == 0):
        return 0
    ################################
    # [lbl_def]
    lbl_def = parse_lbl_def(tokens, symbols, code, line)
    if(lbl_def):
        if(lbl_def == er):
            return er
        data.append(lbl_def)


##############################################################################################################
code_lines, tokens = lexer(read("programs/demo.asm"));

if(code_lines == 0)
    sys.exit(1)

tree = []



