import copy


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
    indices_good = []
    for idx, line in enumerate(lines):
        line = line.strip()
        sequence_of_values = [int(x) for x in line.split(" ")]
        all_sequences = [copy.deepcopy(sequence_of_values)]
        for i in range(len(sequence_of_values)):
            tmp = copy.deepcopy(sequence_of_values)
            tmp.pop(i)
            all_sequences.append(tmp)

        is_good = any(valid_sequence(seq) for seq in all_sequences)
        if is_good:
            indices_good.append(idx)
            total += 1

    # print(indices_good)
    print(total)
        
if __name__ == "__main__":
    main()
