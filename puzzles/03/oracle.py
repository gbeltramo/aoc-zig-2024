def valid_sequence(sequence: list[int]) -> bool:

    if len(sequence) < 2:
        return False

    if sequence[0] == sequence[1]:
        return False
    
    if sequence[0] < sequence[1]:
        for idx in range(1, len(sequence)):
            a = sequence[idx-1]
            b = sequence[idx]
            if (a >= b) or ((b - a) > 3):
                return False

    if sequence[0] > sequence[1]:
        for idx in range(1, len(sequence)):
            a = sequence[idx-1]
            b = sequence[idx]
            if (a <= b) or ((a - b) > 3):
                return False

    return True

    
def main():
    with open("input.txt", "r") as f:
        lines = f.readlines()
    # print(len(lines))

    total = 0
    for line in lines:
        line = line.strip()
        sequence_of_values = [int(x) for x in line.split(" ")]
        total += valid_sequence(sequence_of_values)
        #print(sequence_of_values)

    print(total)
        
if __name__ == "__main__":
    main()
