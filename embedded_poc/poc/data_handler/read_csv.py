import csv

def read_csv_header(file_name):
    header = []
    with open(file_name) as file:
        reader = csv.reader(file, delimiter=',')
        head = reader.__next__()
        for i in head:
            header.append(int(i))
        file.close()
        return header

def read_csv_data(file_name):
    data = []
    line_count = 1
    with open(file_name) as file:
        reader = csv.reader(file, delimiter=',')
        reader.__next__()
        for row in reader:
            temp = []
            for i in row:
                temp.append(int(i))
            data.append(temp)
            line_count += 1
        print('Total lines read = ', line_count)
        file.close()
        return data
