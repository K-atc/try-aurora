import re
import subprocess
import os
import select

def convert_address_to_offset(line, base_addr):
    def repl(match):
        abs_addr = int(match.group(0), 16)
        offset = abs_addr - base_addr
        return f"0x{offset:x}"
    return re.sub(r"0x[0-9a-fA-F]+", repl, line)

class Addr2Line:
    def __init__(self, exe_path):
        self.exe_path = exe_path
        self.process = subprocess.Popen(
            ["llvm-addr2line-16", "-e", exe_path, "-f", "--print-source-context-lines=1", "--output-style=LLVM"],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            bufsize=0  # Unbuffered for immediate I/O
        )
        self.script_dir = os.path.dirname(os.path.abspath(__file__))
    
    def query(self, line):
        """Send a line to addr2line process and get the result"""
        try:
            # Send the line to addr2line
            self.process.stdin.write(line + '\n')
            self.process.stdin.flush()
            
            # Read the output
            # addr2line typically outputs multiple lines for each address
            # We need to read until we get all the output for this query
            output_lines = []
            
            # Read lines until we find the end marker or empty line
            # The exact behavior depends on addr2line version and options
            while True:
                ready, _, _ = select.select([self.process.stdout], [], [], 2.0)
                if not ready:
                    break

                line_out = self.process.stdout.readline()
                if not line_out:
                    break
                output_lines.append(line_out)
                
                # Check if this looks like the end of output for this query
                # This heuristic may need adjustment based on your addr2line version
                if line_out.strip() == '' or line_out.startswith('0x'):
                    # Try to read one more line to see if there's more
                    next_line = self.process.stdout.readline()
                    if next_line and next_line.strip():
                        output_lines.append(next_line)
                    else:
                        break


            
            result = ''.join(output_lines)
            
            # Clean up for readability
            result = result.replace(self.script_dir + "/", "")
            return result
            
        except Exception as e:
            return f"Error querying addr2line: {e}\n"
    
    def close(self):
        """Close the addr2line process"""
        if self.process:
            self.process.stdin.close()
            self.process.terminate()
            self.process.wait()

def main():
    import argparse
    parser = argparse.ArgumentParser(description="addr2line of addresses appearing in log files")
    parser.add_argument("EXE_FILE", help="Executable file wanted to be analyzed")
    parser.add_argument("INPUT_FILE", help="Input file with absolute addresses")
    parser.add_argument("--base", type=lambda x: int(x,0), default=0x555555554000)
    args = parser.parse_args()
    
    # Initialize the persistent addr2line process
    addr2line_proc = Addr2Line(args.EXE_FILE)
    
    try:
        with open(args.INPUT_FILE, "r") as fin:
            for i, line in enumerate(fin):
                print(f"Rank #{i + 1}")
                print(line, end="")  # Print original line
                converted_line = convert_address_to_offset(line, args.base)
                addr2line_output = addr2line_proc.query(converted_line)
                print(addr2line_output, end="")  # Print addr2line output
    finally:
        # Make sure to close the process when done
        addr2line_proc.close()

if __name__ == "__main__":
    main()