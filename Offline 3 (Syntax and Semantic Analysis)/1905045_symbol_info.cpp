#include<string>

using namespace std;

class SymbolInfo {
    string name;
    string type;
    SymbolInfo *next_symbol;
    bool isArray;
    bool isFunction;

    void init() {
        setNextSymbol(nullptr);
        setArray(false);
        setFunction(false);
    }

public:
    SymbolInfo() {
        init();
    }

    SymbolInfo(const string &name, const string &type) {
        setName(name);
        setType(type);
        init();
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

    void setArray(bool isArray) {
        this->isArray = isArray;
    }

    bool getArray() {
        return isArray;
    }

    void setFunction(bool isFunction) {
        this->isFunction = isFunction;
    }

    bool getFunction() {
        return isFunction;
    }
};
