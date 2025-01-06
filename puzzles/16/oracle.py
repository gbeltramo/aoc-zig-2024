import argparse
import pathlib

def check_on_line(x1, y1, x2, y2, x3, y3):
    return (x2 - x1) * (y3 - y1) == (x3 - x1) * (y2 - y1)

def main(input_path: pathlib.Path) -> None:
    # Read input
    with open(input_path, "r") as f:
        lines = f.readlines()

    # Partition antennas
    antennas = dict()
    num_rows, num_cols = len(lines), len(lines[0]) - 1
    for row_i in range(num_rows):
        for col_i in range(num_cols):
            c: str = lines[row_i][col_i]
            if c != ".":
                if c in antennas:
                    antennas[c].append((row_i, col_i))
                else:
                    antennas[c] = [(row_i, col_i)]

    total = 0
    antinodes = set()
    for c in antennas.keys():
        for idx, (x1, x2) in enumerate(antennas[c]):
            for y1, y2 in antennas[c][idx+1:]:
                    for z1 in range(num_rows):
                        for z2 in range(num_cols):
                            if check_on_line(z1, z2, x1, x2, y1, y2):
                                antinodes.add((z1, z2))


    print(f"INFO: The solution to puzzle 16 is: {len(antinodes)}")




if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--input_path", type=str, help="Path to input file of puzzle 16")
    args = parser.parse_args()

    input_path = pathlib.Path(args.input_path)
    assert input_path.exists(), f"{input_path.absolute()} does not exist"
    
    main(input_path)
