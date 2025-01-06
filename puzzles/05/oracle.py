import re


def main():
    with open("input.txt", "r") as f:
        content = f.read()

    total = 0
    for found_mul in re.findall(r'mul\(\d{0,3},\d{0,3}\)', content, flags=re.ASCII):
        parts = found_mul.split(",")
        num1 = int(parts[0][4:])
        num2 = int(parts[1][:-1])
        # print(num1, num2)
        total += num1 * num2

    print(total)
    
if __name__ == "__main__":
    main()
