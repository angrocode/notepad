'''
Clear language csv
https://www.fuzzwork.co.uk/dump/latest/trnTranslations.csv.bz2
'''

import csv
import re


def translations_csv_clear(path_in):
    header_in = open(file=path_in, mode='r', encoding='utf-8')
    reader = csv.DictReader(header_in)
    fieldnames = reader.fieldnames

    path_out = str()
    path = path_in.split('\\')
    for num, pstr in enumerate(path):
        if num < len(path) - 1:
            path_out += pstr + '\\'
        else:
            path_out += 'OUTPUT_' + path[len(path) - 1]

    header_out = open(file=path_out, mode='w', encoding='utf-8', newline='')
    writer = csv.DictWriter(header_out, delimiter=',', fieldnames=fieldnames)
    csv.writer(header_out, delimiter=',').writerow(fieldnames)

    c_br = re.compile(r'(<\s*br\s*>)+', flags=re.M | re.I)
    c_quote = re.compile(r'\'\'|«|»', flags=re.M | re.I)
    c_color = re.compile(r'<\s*color=\s*\'.*?\'\s*>|<\s*/\s*color\s*>', flags=re.M | re.I)
    c_bui = re.compile(r'<b>|</b>|<u>|</u>|</i>|<i>', flags=re.M | re.I)
    c_font = re.compile(r'<\s*font\s*color\s*=.*?>|<\s*font\s*size\s*=.*?>|<\s*/\s*font\s*>', flags=re.M | re.I)
    c_ssymbol = re.compile(r'(\n)+|(\a)+|(\b)+|(\f)+|(\r)+|(\t)+|(\v)+', flags=re.M | re.I)
    c_showinfo = re.compile(r'<\s*a\s*href.*?>\s*|<\s*url.*?>|<\s*/\s*a\s*>|<\s*/\s*url\s*>', flags=re.M | re.I)

    for row in reader:
        row['languageID'] = row['languageID'].replace(r'EN-US', 'en')
        row['languageID'] = row['languageID'].lower()

        row['text'] = c_br.subn(" ", row['text'])[0]
        row['text'] = c_bui.subn("", row['text'])[0]
        row['text'] = c_color.subn("", row['text'])[0]
        row['text'] = c_font.subn("", row['text'])[0]
        row['text'] = c_ssymbol.subn(" ", row['text'])[0]
        row['text'] = c_showinfo.subn("'", row['text'])[0]
        row['text'] = c_quote.subn("", row['text'])[0]

        writer.writerow(row)

    header_in.close()
    header_out.close()


if __name__ == '__main__':
    translations_csv_clear(r'C:\@@@\trnTranslations.csv')
