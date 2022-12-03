#include<iostream>
#include<string>
#include<sstream>
#include "1905045_symbol_table.cpp"

using namespace std;

// replace every whitespace type with ' ' and count no. of words in the string
int format_and_count_words(string &str) {
    int cnt = 0;
    for (int i = 1; i < str.length(); i++) {
        if (str[i] == '\t' || str[i] == 13 || str[i] == 10) { // CR, LF
            str[i] = ' ';
        }
    }
    for (int i = 1; i < str.length(); i++) {
        if (str[i] == ' ' && str[i-1] != ' ') cnt++;
    }
    return cnt;
}

// returns the next word in str after pos
bool find_next_word(const string &str, int pos, int &l, int &r) {
    for (int i = pos; i < str.length(); i++) {
        if (str[i] != ' ') {
            l = i;
            for (int j = i+1; j < str.length(); j++) {
                if (str[j] == ' ') {
                    r = j;
                    return true;
                }
            }
        }
    }
    return false;
}

void insert(string &str, SymbolTable &symTable) {
    int words = format_and_count_words(str);
    if (words != 3) {
        cout << "\tNumber of parameters mismatch for the command I\n";
        return;
    }
    int i, j, pos = 1;
    assert(find_next_word(str, pos, i, j));
    string name = str.substr(i, j-i);
    pos = j+1;
    assert(find_next_word(str, pos, i, j));
    string type = str.substr(i, j-i);
    int idx, table_id;
    bool ret = symTable.insert(name, type, idx, pos, table_id);
    if (ret) {
        cout << "\tInserted in ScopeTable# " << table_id << " at position " << idx+1 << ", " << pos+1 << '\n';
    }
    else {
        cout << "\t\'" << name << "\' already exists in the current ScopeTable\n";
    }
}

void look_up(string &str, SymbolTable &symTable) {
    int words = format_and_count_words(str);
    if (words != 2) {
        cout << "\tNumber of parameters mismatch for the command L\n";
        return;
    }
    int i, j, pos = 1;
    assert(find_next_word(str, pos, i, j));
    string name = str.substr(i, j-i);
    int idx, table_id;
    SymbolInfo *ret = symTable.look_up(name, idx, pos, table_id);
    if (ret != nullptr) {
        cout << "\t\'" << name << "\' found in ScopeTable# " << table_id << " at position " << idx+1 << ", " << pos+1 << '\n';
    }
    else {
        cout << "\t\'" << name << "\' not found in any of the ScopeTables\n";
    }
}

void print_table(string &str, SymbolTable &symTable) {
    int words = format_and_count_words(str);
    if (words != 2) {
        cout << "\tNumber of parameters mismatch for the command P\n";
        return;
    }
    if (str[2] == 'C') {
        symTable.print_current_scope_table();
    }
    else if (str[2] == 'A') {
        symTable.print_all_scope_table();
    }
    else {
        cout << "\tInvalid parameter for the command P\n";
    }
}

void delete_symbol(string &str, SymbolTable &symTable) {
    int words = format_and_count_words(str);
    if (words != 2) {
        cout << "\tNumber of parameters mismatch for the command D\n";
        return;
    }
    int i, j, pos = 1;
    assert(find_next_word(str, pos, i, j));
    string name = str.substr(i, j-i);
    int idx, table_id;
    bool ret = symTable.remove(name, idx, pos, table_id);
    if (ret) {
        cout << "\tDeleted \'" << name << "\' from ScopeTable# " << table_id << " at position " << idx+1 << ", " << pos+1 << '\n';
    }
    else {
        cout << "\tNot found in the current ScopeTable\n";
    }
}

void create_table(string &str, SymbolTable &symTable) {
    int words = format_and_count_words(str);
    if (words != 1) {
        cout << "\tNumber of parameters mismatch for the command S\n";
        return;
    }
    symTable.enter_scope();
}

void exit_table(string &str, SymbolTable &symTable) {
    int words = format_and_count_words(str);
    if (words != 1) {
        cout << "\tNumber of parameters mismatch for the command E\n";
        return;
    }
    bool ret = symTable.exit_scope();
    if (!ret) {
        cout << "\tScopeTable# 1 cannot be removed\n";
    }
}

int main() {
    freopen("sample_input.txt", "r", stdin);
    freopen("my_output.txt", "w", stdout);

    int num_buckets;
    cin >> num_buckets;
    SymbolTable symtable(num_buckets);
    string str;
    int cmd = 1;
    while (1) {
        getline(cin>>ws, str);
        cout << "Cmd " << cmd << ": " << str << '\n';
        if (str[0] == 'Q') {
            break;
        }
        if (str[0] == 'I') {
            insert(str, symtable);
        }
        else if (str[0] == 'L') {
            look_up(str, symtable);
        }
        else if (str[0] == 'P') {
            print_table(str, symtable);
        }
        else if (str[0] == 'D') {
            delete_symbol(str, symtable);
        }
        else if (str[0] == 'S') {
            create_table(str, symtable);
        }
        else if (str[0] == 'E') {
            exit_table(str, symtable);
        }
        else {
            cout << "Invalid command\n";
        }

        cmd++;
    }
    return 0;
}
