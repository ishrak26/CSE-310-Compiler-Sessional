#include <string>
#include <vector>
#include <cassert>

using namespace std;

class SymbolInfo;

class FuncInfo {
    string name;
    vector<SymbolInfo*> params;
    string returnType;

public:
    FuncInfo() {

    }

    FuncInfo(string name) {
        this->name = name;
    }

    void addParam(SymbolInfo* symInfo) {
        params.push_back(symInfo);
    }

    int paramSize() {
        return params.size();
    }

    bool matchParamType(int idx, string type);

    bool checkParam(string name);

    void setReturnType(string returnType) {
        this->returnType = returnType;
    }

    string getReturnType() const {
        return returnType;
    }

};
