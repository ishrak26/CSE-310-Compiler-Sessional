#include<iostream>
#include<string>
#include<cassert>
#include "1905045_symbol_info.cpp"

using namespace std;

class ScopeTable {
    int id;
    int num_buckets;
    SymbolInfo **arr;
    ScopeTable *parent_scope;

    unsigned int SDBMHash(const string &str) const {
        unsigned int hash = 0;
        unsigned int i = 0;
        unsigned int len = str.length();

        for (i = 0; i < len; i++)
        {
            hash = (str[i]) + (hash << 6) + (hash << 16) - hash;
            hash %= num_buckets;
        }

        return hash;
    }

    SymbolInfo *find_in_chain(const string &str, int idx, int task, int &pos) const {
        // task = 0 --> during look up
        // task = 1 --> during insert
        // task = 2 --> during delete
        assert(idx >= 0 && idx < num_buckets);
        assert(task >= 0 && task < 3);
        SymbolInfo *prev = arr[idx];
        SymbolInfo *curr = arr[idx];
        pos = 0;
        while (curr != nullptr) {
            if (curr->getName() == str) {
                // found
                if (task == 2) {
                    return prev;
                }
                return curr;
            }
            prev = curr;
            curr = curr->getNextSymbol();
            pos++;
        }
        // not found
        if (task == 0 || task == 2) {
            // lookup/delete
            return nullptr;
        }
        // task = 1
        return prev;
        // tail of the chain during insert
        // previous entry during delete
    }

    void print_bucket(int idx) {
        cout << idx+1 << "-->";
        SymbolInfo *curr = arr[idx];
        while (curr != nullptr) {
            cout << " <" << curr->getName() << ',' << curr->getType() << '>';
            curr = curr->getNextSymbol();
        }
        cout << '\n';
    }

    void delete_bucket(int idx) {
        SymbolInfo *curr = arr[idx];
        while (curr != nullptr) {
            SymbolInfo *tmp = curr->getNextSymbol();
            delete curr;
            curr = tmp;
        }
    }

public:
    ScopeTable(int n, int id) {
        num_buckets = n;
        this->id = id;
        arr = new SymbolInfo*[n];
    }

    ~ScopeTable() {
        for (int i = 0; i < num_buckets; i++) {
            delete_bucket(i);
        }
        delete[] arr;
    }

    // returns false if not found
    bool insert(const string &symbol, const string &type, int &idx, int &pos) {
        idx = SDBMHash(symbol);
        SymbolInfo *ret = find_in_chain(symbol, idx, 1, pos);
        if (ret == nullptr || ret->getName() != symbol) {
            // not found
            // need to insert
            SymbolInfo *new_sym = new SymbolInfo(symbol, type);
            if (ret == nullptr) {
                arr[idx] = new_sym;
            }
            else {
                ret->setNextSymbol(new_sym);
            }
            return true;
        }
        else {
            // found
            // don't insert
            return false;
        }
    }

    // returns null if not found
    SymbolInfo *look_up(const string &symbol, int &idx, int &pos) {
        idx = SDBMHash(symbol);
        return find_in_chain(symbol, idx, 0, pos);
    }

    // returns true if deletion is successful
    bool deleteSymbol(const string &symbol, int &idx, int &pos) {
        idx = SDBMHash(symbol);
        SymbolInfo *sym = find_in_chain(symbol, idx, 2, pos);
        if (sym == nullptr) {
            // nothing to delete
            return false;
        }
        else {
            if (sym->getName() == symbol) {
                // it was the first element in that idx
                SymbolInfo *tmp = sym->getNextSymbol();
                arr[idx] = tmp;
                delete sym;
            }
            else {
                SymbolInfo *tmp = sym->getNextSymbol();
                sym->setNextSymbol(tmp->getNextSymbol());
                delete tmp;
            }
            return true;
        }
    }

    void print() {
        cout << "ScopeTable# " << id << '\n';
        for (int i = 0; i < num_buckets; i++) {
            print_bucket(i);
        }
    }

};
