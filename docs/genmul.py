#!/usr/bin/env python3

limbs = []
acc = 0
for i in range(12):
    limbs.append(acc)
    acc += 22 if i % 4 == 0 else 21

mulparts = []
for i in range(12):
    mulpart = []
    for j in range(12):
        f = j
        g = (i - j) % 12
        mulpart.append(((f, g), limbs[f] + limbs[g] - limbs[i]))
    mulparts.append(mulpart)

tex = ""
for i, row in enumerate(mulparts):
    tex += "$h_{{{i}}}$ & $=$ &".format(i=str(i).rjust(2))
    cells = []
    for cell in row:
        nineteen = 19 if cell[1] >= 255 else 0
        two = 2 if cell[1] % 255 == 1 else 0
        prod = 38 if nineteen and two else nineteen or two
        prodstr = str(prod if prod != 0 else "").rjust(2)
        i, j = [str(x).rjust(2) for x in cell[0]]
        cells.append(" ${prodstr}$ & $f_{{{i}}}g_{{{j}}}$ ".format(**locals()))
    tex += "& $+$ &".join(cells)
    tex += " \\\\\n"
print(tex)
