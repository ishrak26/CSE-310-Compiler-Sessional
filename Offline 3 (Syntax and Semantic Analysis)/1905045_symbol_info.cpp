#include<string>

#include "1905045_function_info.h"

using namespace std;

class SymbolInfo {
    string name;
    string type;
    SymbolInfo *next_symbol;
    bool isArray;
    bool isFunction;
    FuncInfo *funcInfo;
    bool isRule;
    int startLine;
    int endLine;
    vector<SymbolInfo*> treeChildren;

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
        if (isFunction) {
            funcInfo = new FuncInfo(name);
        }
    }

    bool getFunction() {
        return isFunction;
    }

    void setRule(bool isRule) {
        this->isRule = isRule;
    }

    bool getRule() const {
        return isRule;
    }

    void setStartLine(int startLine) {
        this->startLine = startLine;
    }

    int getStartLine() const {
        return startLine;
    }

    void setEndLine(int endLine) {
        this->endLine = endLine;
    }

    int getEndLine() const {
        return endLine;
    }

    void addTreeChild(SymbolInfo* child) {
        treeChildren.push_back(child);
    }

    // pre order traversal
    void printTree(FILE *fp, int treeHeight) {
        for (int i = 0; i < treeHeight; i++) {
            fprintf(fp, " ");
        }
        if (isRule) {
            fprintf(fp, "%s\t<Line: %d-%d>\n", name.c_str(), startLine, endLine);
            for (int i = 0; i < treeChildren.size(); i++) {
                treeChildren[i]->printTree(fp, treeHeight+1);
            }
        }
        else {
            fprintf(fp, "%s : %s\t<Line: %d>\n", type.c_str(), name.c_str(), startLine);
        }
    }
};
