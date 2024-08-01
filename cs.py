# add the folowing alias to your .bashrc
# alias cs='cd d:/app/IBM/log-on/cs/scripts;python cs.py'
#------------------------------------------------------------------------------
# Licensed Materials (c) Copyright Log-On 2024, All Rights Reserved.
#------------------------------------------------------------------------------
import os
import sys
import subprocess

if os.name=='nt':
  import msvcrt
else:
    from getkey import getkey, keys

def get_folder_names(path):
    """
    Takes a path as input and returns a dictionary with keys as the first part of the
    file names(splitted using '_' and considered as integers) and values as a tuple
    of (file name without the first part, file name)
    The dictionary is sorted by the keys in ascending order.
    """
    path = os.path.dirname(os.path.abspath(__file__))


    files = os.listdir(path)
    output_folder = {}
    for f in files:
        if f.split('_')[0].isdigit():  # check if the first part is an integer
            val = f.split('_', 1)[1]  # split the file name and get the second part
            if '.' in val:  # check if there is a '.' in the second part
                val = val.split('.')[0].capitalize().replace('_', ' ')  # get the part before '.' and capitalize it
            else:
                val = val.replace('_', ' ')  # if there is no '.' in the second part, just replace '_' with ' '
            output_folder[int(f.split('_')[0])] = (val, f)  # add the key-value pair to the output dictionary

    return {k: v for k, v in sorted(output_folder.items(), key=lambda item: item[0])}

def cls():
    """
    Clears the terminal window, works on both Windows and Linux/Mac

    Uses the appropriate command depending on the platform the script is running on
    """
    os.system('cls' if os.name=='nt' else 'clear') # on Windows, 'cls' clears the screen; on Linux and Mac, 'clear' does
def bashexec():
    """
    Returns the full path to the bash executable based on the platform.

    On Windows, the executable is located at "C:\\Program Files\\Git\\bin\\bash.exe".
    On Linux and Mac, the executable is located at "/bin/bash".
    """
    return 'd:\\Program Files\\Git\\bin\\bash.exe' if os.name=='nt' else '/bin/bash'




# Your main program loop here


def showMenu():
    """
    Displays a menu of script options and runs the selected script.

    The menu is built from the folders found in the given path, with a Quit option added.
    The user can navigate the menu using the arrow keys and select an option with Enter.
    The selected script is run using the Bash executable.
    """

    folders = get_folder_names("d:/app/IBM/log-on/cs/scripts" if os.name=='nt' else "~/logon/scripts")

    folders['q']=('Quit', 'q')
    keylength=3
    width = max(len(str(key)) + len(val[0]) for key, val in folders.items()) + keylength
    separator = '─' * (width + keylength)
    options=list(folders.items())
    selected=0
    

    while True:
        print_options(options, selected, width, keylength,separator)
        """
        Displays the menu and waits for user input.

        The selected option is run if the user presses Enter.
        The menu is closed if the user presses the Escape key.
        The selected option is changed if the user presses the Up or Down arrow keys.
        """
        key = msvcrt.getch() if os.name=='nt' else  getkey()
        if key==b'q' or key==b'Q' or key=='q' or key=='Q':
            exit(0)
        if key==b'\x1b[A' or key==b'H' or key=='\x1b[A':
            if selected>0:
                selected-=1
        elif key==b'\x1b[B' or key==b'P' or key=='\x1b[B':
            if selected<len(options)-1:
                selected+=1
        elif key==b'\r' or key==b'\n' or key=='\n':
            if options[selected][0]=='q':
                exit(0)
            script=options[selected][1][1]            
            bashexe=bashexec()
            print(f'Doing {options[selected][1][1]} : {bashexe} {script}')
            subprocess.Popen([bashexe, "-c", "./"+script])
            
        elif key=='\x1b' or key=='[':
            break

def print_options(options, selected, width, keylength,separator):
    """
    Prints the menu options to the console.

    options is a list of tuples of (key, (value, script))
    selected is the index of the currently selected option
    width is the total width of the menu (including the separators)
    keylength is the length of the longest key
    separator is the character to use for the horizontal line
    """
    cls()
    print('┌' + separator + '┐') # Start of the top line
    for i, (key, val) in enumerate(options): # Loop through all the options
        print('│ ',end='') # Print the left edge of the box
        if i==selected: # If this is the selected option
            print('\033[44m', end='') # Print the ANSI code to highlight it
        print( str(key).ljust(keylength) + ' ' + val[0] + ' '*(width-keylength-len(val[0])+1), end='') # Print the option text
        if i==selected: # If this was the selected option
            print('\033[0m', end='') # Reset the colours
        print('│') # Print the right edge of the box
    print('└' +  separator + '┘') # End of the bottom line

showMenu()

