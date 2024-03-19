import sys
import tty
import termios

class _Getch:
  def __call__(self):
    fd = sys.stdin.fileno()
    old_settings = termios.tcgetattr(fd)
    try:
      tty.setraw(fd)
      ch = sys.stdin.read(3)
    finally:
      termios.tcsetattr(fd, termios.TCSADRAIN, old_settings)
    return ch

def get():
  inkey = _Getch()
  while True:
    k = inkey()
    if k != '':
      break
  if k == '\x1b[A':
    return "up"
  elif k == '\x1b[B':
    return "down"
  # Add cases for other arrow keys (left, right) as needed

while True:
  key = get()
  if key == "up":
    print("Up arrow pressed!")
  elif key == "down":
    print("Down arrow pressed!")
  # Handle other keys as needed

