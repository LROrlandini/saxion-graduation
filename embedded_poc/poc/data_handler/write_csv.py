import csv

empty = None


def build_header():
    header = []
    column = 0
    for _ in range (0, 144):
        header.append(str(column))
        column += 1
    header.append(144)
    return header


def check_if_empty(file_name):
    global empty
    with open(file_name, 'r') as file:
        empty = file.read(1)
        file.close()
        if not empty:
            return True
        return False


def write_csv_data(file_name, features):
    global empty
    if empty is None:
        empty = check_if_empty(file_name)
    with open(file_name, mode='a+', newline='') as file:
        writer = csv.writer(file, delimiter=',')
        if empty:
            writer.writerow(build_header())
            empty = False
        writer.writerow(features)
    file.close()


def delete_bad_csv_data(file_name):
    with open(file_name, 'r+') as file:
        lines = file.readlines()
        file.close()
        for _ in range (0, 6):
            lines.pop()
    with open(file_name, 'w+') as file:
        file.writelines(lines)