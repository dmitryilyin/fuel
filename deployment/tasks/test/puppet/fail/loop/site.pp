notify { 'A' :}
notify { 'B' :}

Notify['A'] -> Notify['B']
Notify['B'] -> Notify['A']