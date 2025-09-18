import re

def convert_address_to_offset(line, base_addr):
    def repl(match):
        abs_addr = int(match.group(0), 16)
        offset = abs_addr - base_addr
        return f"0x{offset:x}"

    return re.sub(r"0x[0-9a-fA-F]+", repl, line)

# cat evaluation/ranked_predicates.txt | llvm-addr2line-16 -e evaluation/tiff_read_rgba_fuzzer_trace -f --addresses --relativenames --print-source-context-lines=1 
def addr2line(line, exe_path):
    import subprocess
    result = subprocess.run(
        ["llvm-addr2line-16", "-e", exe_path, "--relativenames", "-f", "--print-source-context-lines=1", "--output-style=LLVM"],
        input=line,
        text=True,
        capture_output=True
    )
    return result.stdout

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description="addr2line of addresses appearing in log files")
    parser.add_argument("EXE_FILE", help="Executable file wanted to be analyzed")
    parser.add_argument("INPUT_FILE", help="Input file with absolute addresses")
    parser.add_argument("--base", type=lambda x: int(x,0), default=0x555555554000)
    args = parser.parse_args()

    with open(args.INPUT_FILE, "r") as fin:
        for line in fin:
            print(line, end="")  # Print original line
            converted_line = convert_address_to_offset(line, args.base)
            addr2line_output = addr2line(converted_line, args.EXE_FILE)

            ### Clean up for readability
            import os
            script_dir = os.path.dirname(os.path.abspath(__file__))
            addr2line_output = addr2line_output.replace(script_dir + "/", "")

            print(addr2line_output, end="")  # Print addr2line output
