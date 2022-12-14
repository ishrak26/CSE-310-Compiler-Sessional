#include<iostream>
#include<string>
#include<cassert>
#include "1905045_scope_table.cpp"

using namespace std;

class SymbolTable {
    static int table_no;
    int num_buckets;
    ScopeTable *curr_scope;

public:
    SymbolTable(int buckets) {
        // create the first scope
        table_no = 1;
        this->num_buckets = buckets;
        curr_scope = new ScopeTable(buckets, table_no);
        curr_scope->setParentScope(nullptr);
    }

    ~SymbolTable() {
        ScopeTable *tmp;
        while (curr_scope != nullptr) {
            tmp = curr_scope->getParentScope();
            delete curr_scope;
            curr_scope = tmp;
        }
    }

    void enter_scope() {
        table_no++;
        ScopeTable *new_scope = new ScopeTable(num_buckets, table_no);
        new_scope->setParentScope(curr_scope);
        curr_scope = new_scope;
    }

    bool exit_scope() {
        if (curr_scope->getParentScope() == nullptr) {
            // cannot exit the first scope
            return false;
        }
        ScopeTable *tmp = curr_scope->getParentScope();
        delete curr_scope;
        curr_scope = tmp;
        return true;
    }

    bool insert(const string &name, const string &type, int &idx, int &pos, int &table_id) {
        table_id = curr_scope->getID();
        return curr_scope->insert(name, type, idx, pos);
    }

    bool remove(const string &name, int &idx, int &pos, int &table_id) {
        table_id = curr_scope->getID();
        return curr_scope->deleteSymbol(name, idx, pos);
    }

    SymbolInfo *look_up(const string &name, int &idx, int &pos, int &table_id) {
        ScopeTable *curr = curr_scope;
        SymbolInfo *ret;
        while (curr != nullptr) {
            ret = curr->look_up(name, idx, pos);
            if (ret != nullptr) {
                table_id = curr->getID();
                return ret;
            }
            curr = curr->getParentScope();
        }
        return nullptr;
    }

    void print_current_scope_table() {
        curr_scope->print();
    }

    void print_all_scope_table() {
        ScopeTable *curr = curr_scope;
        while (curr != nullptr) {
            curr->print();
            curr = curr->getParentScope();
        }
    }
};

int SymbolTable::table_no;
