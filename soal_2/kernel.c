int cursor = 0;
char color = 0x07;

void putInMemory(int segment, int address, char character);
int getChar();

/*
 * Final Challenge
 *
 * Commands:
 * - check
 * - add <a> <b>
 * - sub <a> <b>
 * - fac <n>
 * - season <name>
 * - triangle <n>
 * - clear
 * - about
 *
 * Season list:
 * - winter
 * - spring
 * - summer
 * - fall
 * - radiant
 *
 * Restrictions:
 * - no stdlib
 * - avoid division (/)
 * - avoid modulo (%)
 */

/* =========================================================
 * 1. printChar
 * ========================================================= */
void printChar(char c) {
    putInMemory(0xB800, cursor * 2,     c);
    putInMemory(0xB800, cursor * 2 + 1, color);
    cursor++;
}

/* =========================================================
 * newline helper  (no % needed: just walk to col boundary)
 * ========================================================= */
void newline() {
    /* screen is 80 columns wide; advance until cursor sits on col 0 of next row */
    int row = 0;
    int col;
    /* find current col: col = cursor - row*80, walk row up until row*80 <= cursor */
    while ((row + 1) * 80 <= cursor) row++;
    col = cursor - row * 80;
    if (col != 0) cursor = cursor + (80 - col);
}

/* =========================================================
 * 2. printString
 * ========================================================= */
void printString(char *s) {
    int i = 0;
    while (s[i] != '\0') {
        printChar(s[i]);
        i++;
    }
}

/* =========================================================
 * 3. clearScreen
 * ========================================================= */
void clearScreen() {
    int i;
    for (i = 0; i < 2000; i++) {
        putInMemory(0xB800, i * 2,     ' ');
        putInMemory(0xB800, i * 2 + 1, 0x07);
    }
    cursor = 0;
    color  = 0x07;
}

/* =========================================================
 * 4. readString
 * ========================================================= */
void readString(char *buf) {
    int  i = 0;
    char c;
    while (1) {
        c = getChar();
        if (c == '\r' || c == '\n') {
            buf[i] = '\0';
            return;
        }
        if (c == '\b') {
            if (i > 0) {
                i--;
                cursor--;
                putInMemory(0xB800, cursor * 2,     ' ');
                putInMemory(0xB800, cursor * 2 + 1, color);
            }
            continue;
        }
        buf[i] = c;
        i++;
        printChar(c);
    }
}

/* =========================================================
 * 5. strcmp  â€“ returns 1 if equal, 0 otherwise
 * ========================================================= */
int strcmp(char *a, char *b) {
    int i = 0;
    while (a[i] != '\0' && b[i] != '\0') {
        if (a[i] != b[i]) return 0;
        i++;
    }
    return (a[i] == '\0' && b[i] == '\0');
}

/* =========================================================
 * 6. startsWith â€“ returns 1 if s starts with prefix
 * ========================================================= */
int startsWith(char *s, char *prefix) {
    int i = 0;
    while (prefix[i] != '\0') {
        if (s[i] != prefix[i]) return 0;
        i++;
    }
    return 1;
}

/* =========================================================
 * 7. atoi  (no / or %)
 * ========================================================= */
int atoi(char *s) {
    int result = 0;
    int sign   = 1;
    int i      = 0;
    while (s[i] == ' ') i++;
    if (s[i] == '-') { sign = -1; i++; }
    while (s[i] >= '0' && s[i] <= '9') {
        result = result * 10 + (s[i] - '0');
        i++;
    }
    return result * sign;
}

/* =========================================================
 * 8. intToString  (no / or % : use repeated subtraction)
 * ========================================================= */
void intToString(int n, char *buf) {
    /* digits stored LSB-first, then reversed */
    char tmp[7];
    int  count = 0;
    int  i, j;
    int  neg = 0;
    int  rem, q;

    if (n == 0) { buf[0] = '0'; buf[1] = '\0'; return; }
    if (n < 0)  { neg = 1; n = -n; }

    while (n > 0) {
        /* compute n % 10 and n / 10 via subtraction */
        rem = n; q = 0;
        while (rem >= 10) { rem -= 10; q++; }
        tmp[count] = '0' + rem;
        count++;
        n = q;
    }

    i = 0;
    if (neg) { buf[i] = '-'; i++; }
    /* reverse digits (they are LSB-first) */
    j = count;
    while (j > 0) {
        j--;
        buf[i] = tmp[j];
        i++;
    }
    buf[i] = '\0';
}

/* =========================================================
 * 9. factorial  â€“ returns -1 on overflow (16-bit max 32767)
 * ========================================================= */
int factorial(int n) {
    int result = 1;
    int i;
    if (n < 0) return -1;
    for (i = 2; i <= n; i++) {
        result = result * i;
        if (result < 0) return -1; /* signed overflow */
    }
    return result;
}

/* =========================================================
 * Argument parsers
 * ========================================================= */
void parseStr(char *cmd, char *out) {
    int i = 0, j = 0;
    /* skip command word */
    while (cmd[i] != ' ' && cmd[i] != '\0') i++;
    /* skip spaces */
    while (cmd[i] == ' ') i++;
    /* copy rest */
    while (cmd[i] != '\0') { out[j] = cmd[i]; j++; i++; }
    out[j] = '\0';
}

void parseTwoInts(char *cmd, int *a, int *b) {
    char tmp[12];
    int i = 0, j;
    while (cmd[i] != ' ' && cmd[i] != '\0') i++;
    while (cmd[i] == ' ') i++;
    j = 0;
    while (cmd[i] != ' ' && cmd[i] != '\0') { tmp[j] = cmd[i]; j++; i++; }
    tmp[j] = '\0'; *a = atoi(tmp);
    while (cmd[i] == ' ') i++;
    j = 0;
    while (cmd[i] != '\0') { tmp[j] = cmd[i]; j++; i++; }
    tmp[j] = '\0'; *b = atoi(tmp);
}

void parseOneInt(char *cmd, int *a) {
    char tmp[12];
    int i = 0, j = 0;
    while (cmd[i] != ' ' && cmd[i] != '\0') i++;
    while (cmd[i] == ' ') i++;
    while (cmd[i] != '\0') { tmp[j] = cmd[i]; j++; i++; }
    tmp[j] = '\0'; *a = atoi(tmp);
}

/* =========================================================
 * 14. printTriangle
 * ========================================================= */
void printTriangle(int n) {
    int i, j;
    for (i = 1; i <= n; i++) {
        for (j = 0; j < i; j++) printChar('x');
        newline();
    }
}

/* =========================================================
 * main â€“ shell loop
 * ========================================================= */
void main() {

    char cmd[64];
    char arg[32];
    char numStr[12];
    int  a, b, res;

    clearScreen();

    printString("Welcome to Assistant's Last Gift");
    newline();
    printString("type 'help'");
    newline();
    newline();

    while (1) {

        printString("> ");
        readString(cmd);
        newline();

        /* check */
        if (strcmp(cmd, "check")) {
            printString("ok");

        /* help */
        } else if (strcmp(cmd, "help")) {
            printString("check add sub fac season triangle clear about");

        /* about */
        } else if (strcmp(cmd, "about")) {
            printString("Assistant's Last Gift - SISOP Final");

        /* 10. add */
        } else if (startsWith(cmd, "add ")) {
            parseTwoInts(cmd, &a, &b);
            intToString(a + b, numStr);
            printString(numStr);

        /* 11. sub */
        } else if (startsWith(cmd, "sub ")) {
            parseTwoInts(cmd, &a, &b);
            intToString(a - b, numStr);
            printString(numStr);

        /* 12. fac */
        } else if (startsWith(cmd, "fac ")) {
            parseOneInt(cmd, &a);
            res = factorial(a);
            if (res == -1) {
                printString("know your limit little bro.");
            } else {
                intToString(res, numStr);
                printString(numStr);
            }

        /* 13. season */
        } else if (startsWith(cmd, "season ")) {
            parseStr(cmd, arg);
            if (strcmp(arg, "winter")) {
                color = 0x0B;               /* bright cyan  */
                printString("winter mode");
            } else if (strcmp(arg, "spring")) {
                color = 0x0A;               /* bright green */
                printString("spring mode");
            } else if (strcmp(arg, "summer")) {
                color = 0x0E;               /* yellow       */
                printString("summer mode");
            } else if (strcmp(arg, "fall")) {
                color = 0x0C;               /* bright red   */
                printString("fall mode");
            } else if (strcmp(arg, "radiant")) {
                color = 0x0D;               /* bright magenta */
                printString("radiant mode");
            } else {
                printString("unknown season");
            }

        /* 14. triangle */
        } else if (startsWith(cmd, "triangle ")) {
            parseOneInt(cmd, &a);
            newline();
            printTriangle(a);
            continue;  /* skip extra newline */

        /* clear */
        } else if (strcmp(cmd, "clear")) {
            clearScreen();
            continue;

        } else {
            if (cmd[0] != '\0') printString("unknown command");
        }

        newline();
    }
}
