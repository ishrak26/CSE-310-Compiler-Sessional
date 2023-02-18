#include<string>

#include "1905045_function_info.h"

using namespace std;

class SymbolInfo {
    string name;
    string type;
    string dataType;
    SymbolInfo *next_symbol;
    bool isArray;
    int arraySize;
    bool isFunction;
    FuncInfo *funcInfo;
    bool isRule;
    int startLine;
    int endLine;
    vector<SymbolInfo*> treeChildren;
    string constVal;
    bool funcParamNoName; // to handle function declaration
    bool isGlobal;
    int stackOffset;
    string varName;
    bool isBool;
    vector<int> truelist;
    vector<int> falselist;

    void init() {
        setNextSymbol(nullptr);
        setArray(false);
        setFunction(false);
        setRule(false);
        setFuncParamNoName(false);
        setGlobal(false);

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

    SymbolInfo(const SymbolInfo* symInfo) {
        name = symInfo->getName();
        type = symInfo->getType();
        dataType = symInfo->getDataType();
        next_symbol = symInfo->getNextSymbol();
        isArray = symInfo->getArray();
        arraySize = symInfo->getArraySize();
        isFunction = symInfo->getFunction();
        funcInfo = symInfo->getFuncInfo();
        isRule = symInfo->getRule();
        startLine = symInfo->getStartLine();
        endLine = symInfo->getEndLine();
        funcParamNoName = symInfo->getFuncParamNoName();
    }

    ~SymbolInfo() {
        if (isFunction) {
            delete funcInfo;
        }
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

    bool getArray() const {
        return isArray;
    }

    void setFunction(bool isFunction) {
        this->isFunction = isFunction;
        if (isFunction) {
            funcInfo = new FuncInfo(name);
        }
    }

    bool getFunction() const {
        return isFunction;
    }

    void setFuncReturnType(string returnType) {
        if (isFunction) {
            funcInfo->setReturnType(returnType);
        }
    }

    string getFuncReturnType() const {
        if (isFunction) {
            return funcInfo->getReturnType();
        }
        return "";
    }

    int getFuncParamCount() const {
        if (isFunction) {
            return funcInfo->paramSize();
        }
        return 0;
    }

    bool matchFuncParamType(int idx, string type) {
        if (isFunction) {
            return funcInfo->matchParamType(idx, type);
        }
        return false;
    }

    FuncInfo* getFuncInfo() const {
        return funcInfo;
    }

    void addFuncParam(SymbolInfo* symInfo) {
        if (isFunction) {
            return funcInfo->addParam(symInfo);
        }
    }

    bool checkFuncParam(string name) {
        if (isFunction) {
            return funcInfo->checkParam(name);
        }
        return false;
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

    // post-order traversal
    void destroyTree() {
        if (isRule) {
            for (int i = 0; i < int(treeChildren.size()); i++) {
                if (!treeChildren[i]->getFunction()) {
                    treeChildren[i]->destroyTree();
                    delete treeChildren[i];
                }
            }
        }
    }

    void setDataType(string dataType) {
        this->dataType = dataType;
    }

    string getDataType() const {
        return dataType;
    }

    void setArraySize(int arraySize) {
        this->arraySize = arraySize;
    }

    int getArraySize() const {
        return arraySize;
    }

    void setConstVal(string val) {
        constVal = val;
    }

    string getConstVal() const {
        return constVal;
    }

    void setFuncParamNoName(bool val) {
        funcParamNoName = val;
    }

    bool getFuncParamNoName() const {
        return funcParamNoName;
    }

    void setGlobal(bool isGlobal) {
        this->isGlobal = isGlobal;
    }

    bool getGlobal() const {
        return isGlobal;
    }

    void setStackOffset(int stackOffset) {
        this->stackOffset = stackOffset;
    }

    int getStackOffset() const {
        return stackOffset;
    }

    void setVarName(const string &varName) {
        this->varName = varName;
    }

    string getVarName() const {
        return varName;
    }

    void setBool(bool isBool) {
        this->isBool = isBool;
    }

    bool getBool() const {
        return isBool;
    }

    void insertIntoTruelist(int val) {
        truelist.push_back(val);
    }

    void insertIntoTruelist(vector<int> &list) {
        for (int i = 0; i < list.size(); i++) {
            insertIntoTruelist(list[i]);
        }
    }
    
    void insertIntoFalselist(int val) {
        falselist.push_back(val);
    }

    void insertIntoFalselist(vector<int> &list) {
        for (int i = 0; i < list.size(); i++) {
            insertIntoFalselist(list[i]);
        }
    }

    vector<int> getTruelist() const {
        return this->truelist;
    }

    vector<int> getFalselist() const {
        return this->falselist;
    }
};
