#include<string>

using namespace std;

class SymbolInfo {
    string name;
    string type;
    SymbolInfo *next_symbol;

public:
    SymbolInfo() {
        setNextSymbol(nullptr);
    }

    SymbolInfo(const string &name, const string &type) {
        setName(name);
        setType(type);
        setNextSymbol(nullptr);
    }

    void setName(const string &name) {
        this->name = name;
    }

    string getName() const {
        return name;
    }

    void setType(const string &type) {
        this->type = type;
    }

    string getType() const {
        return type;
    }

    void setNextSymbol(SymbolInfo *next_symbol) {
        this->next_symbol = next_symbol;
    }

    SymbolInfo *getNextSymbol() const {
        return next_symbol;
    }
};
