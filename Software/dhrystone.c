/*
 * Simplified Dhrystone Benchmark for MinCPU
 * Based on Dhrystone 2.1 by Reinhold P. Weicker
 * Adapted for embedded RISC-V systems without libc
 */

// Simple types for Dhrystone
typedef int Enumeration;
typedef int One_Thirty;
typedef int One_Fifty;
typedef char Capital_Letter;
typedef int Boolean;
typedef char Str_30[31];
typedef int Arr_1_Dim[50];
typedef int Arr_2_Dim[50][50];

typedef struct record {
    struct record *Ptr_Comp;
    Enumeration    Discr;
    union {
        struct {
            Enumeration Enum_Comp;
            int         Int_Comp;
            Boolean     Bool_Comp;
        } var_1;
        struct {
            Enumeration Enum_Comp_2;
            char        Str_Comp[31];
        } var_2;
        struct {
            int         Int_Comp_2;
            char        Str_2_Comp[31];
        } var_3;
    } variant;
} Rec_Type, *Rec_Pointer;

// Enumeration constants
#define Ident_1 0
#define Ident_2 1  
#define Ident_3 2
#define Ident_4 3
#define Ident_5 4

// Global variables
Rec_Pointer     Ptr_Glob, Next_Ptr_Glob;
int             Int_Glob;
Boolean         Bool_Glob;
char            Ch_1_Glob, Ch_2_Glob;
Arr_1_Dim       Arr_1_Glob;
Arr_2_Dim       Arr_2_Glob;

// Number of runs for benchmarking
#define LOOPS 1000

// Function prototypes
void Proc_1(Rec_Pointer Ptr_Val_Par);
void Proc_2(One_Fifty *Int_Par_Ref);
void Proc_3(Rec_Pointer *Ptr_Ref_Par);
void Proc_4(void);
void Proc_5(void);
void Proc_6(Enumeration Enum_Val_Par, Enumeration *Enum_Ref_Par);
void Proc_7(One_Fifty Int_1_Par_Val, One_Fifty Int_2_Par_Val, One_Fifty *Int_Par_Ref);
void Proc_8(Arr_1_Dim Arr_1_Par_Ref, Arr_2_Dim Arr_2_Par_Ref, int Int_1_Par_Val, int Int_2_Par_Val);
Enumeration Func_1(Capital_Letter Ch_1_Par_Val, Capital_Letter Ch_2_Par_Val);
Boolean Func_2(Str_30 Str_1_Par_Ref, Str_30 Str_2_Par_Ref);
Boolean Func_3(Enumeration Enum_Par_Val);

// Simple string operations (no libc)
int Str_Comp(char *s1, char *s2) {
    for (int i = 0; i < 30; i++) {
        if (s1[i] != s2[i]) return s1[i] - s2[i];
        if (s1[i] == 0) break;
    }
    return 0;
}

void Str_Copy(char *dest, char *src) {
    for (int i = 0; i < 30; i++) {
        dest[i] = src[i];
        if (src[i] == 0) break;
    }
}

int main() {
    One_Fifty       Int_1_Loc;
    One_Fifty       Int_2_Loc;
    One_Fifty       Int_3_Loc;
    Capital_Letter  Ch_Index;
    Enumeration     Enum_Loc;
    Str_30          Str_1_Loc;
    Str_30          Str_2_Loc;
    int             Run_Index;

    // Initialize global variables
    Next_Ptr_Glob = (Rec_Pointer) &Arr_1_Glob[0];
    Ptr_Glob = (Rec_Pointer) &Arr_1_Glob[1];
    
    Ptr_Glob->Ptr_Comp = Next_Ptr_Glob;
    Ptr_Glob->Discr = Ident_1;
    Ptr_Glob->variant.var_1.Enum_Comp = Ident_3;
    Ptr_Glob->variant.var_1.Int_Comp = 40;
    Str_Copy(Ptr_Glob->variant.var_1.Bool_Comp, "DHRYSTONE PROGRAM, SOME STRING");
    Str_Copy(Str_1_Loc, "DHRYSTONE PROGRAM, 1'ST STRING");

    Arr_2_Glob[8][7] = 10;

    // Main benchmark loop
    for (Run_Index = 1; Run_Index <= LOOPS; ++Run_Index) {
        Proc_5();
        Proc_4();
        
        Int_1_Loc = 2;
        Int_2_Loc = 3;
        Str_Copy(Str_2_Loc, "DHRYSTONE PROGRAM, 2'ND STRING");
        Enum_Loc = Ident_2;
        Bool_Glob = !Func_2(Str_1_Loc, Str_2_Loc);

        while (Int_1_Loc < Int_2_Loc) {
            Int_3_Loc = 5 * Int_1_Loc - Int_2_Loc;
            Proc_7(Int_1_Loc, Int_2_Loc, &Int_3_Loc);
            Int_1_Loc += 1;
        }

        Proc_8(Arr_1_Glob, Arr_2_Glob, Int_1_Loc, Int_3_Loc);
        Proc_1(Ptr_Glob);
        
        for (Ch_Index = 'A'; Ch_Index <= Ch_2_Glob; ++Ch_Index) {
            if (Enum_Loc == Func_1(Ch_Index, 'C')) {
                Proc_6(Ident_1, &Enum_Loc);
                Str_Copy(Str_2_Loc, "DHRYSTONE PROGRAM, 3'RD STRING");
                Int_2_Loc = Run_Index;
                Int_Glob = Run_Index;
            }
        }

        Int_2_Loc = Int_2_Loc * Int_1_Loc;
        Int_1_Loc = Int_2_Loc / Int_3_Loc;
        Int_2_Loc = 7 * (Int_2_Loc - Int_3_Loc) - Int_1_Loc;
        Proc_2(&Int_1_Loc);
    }

    // Simple result output (no printf)
    return LOOPS;
}

void Proc_1(Rec_Pointer Ptr_Val_Par) {
    Rec_Pointer Next_Record = Ptr_Val_Par->Ptr_Comp;
    
    *Ptr_Val_Par->Ptr_Comp = *Ptr_Glob;
    Ptr_Val_Par->variant.var_1.Int_Comp = 5;
    Next_Record->variant.var_1.Int_Comp = Ptr_Val_Par->variant.var_1.Int_Comp;
    Next_Record->Ptr_Comp = Ptr_Val_Par->Ptr_Comp;
    Proc_3(&Next_Record->Ptr_Comp);
    
    if (Next_Record->Discr == Ident_1) {
        Next_Record->variant.var_1.Int_Comp = 6;
        Proc_6(Ptr_Val_Par->variant.var_1.Enum_Comp, &Next_Record->variant.var_1.Enum_Comp);
        Next_Record->Ptr_Comp = Ptr_Glob->Ptr_Comp;
        Proc_7(Next_Record->variant.var_1.Int_Comp, 10, &Next_Record->variant.var_1.Int_Comp);
    } else {
        *Ptr_Val_Par = *Ptr_Val_Par->Ptr_Comp;
    }
}

void Proc_2(One_Fifty *Int_Par_Ref) {
    One_Fifty Int_Loc = *Int_Par_Ref + 10;
    Enumeration Enum_Loc;

    do {
        if (Ch_1_Glob == 'A') {
            Int_Loc -= 1;
            *Int_Par_Ref = Int_Loc - Int_Glob;
            Enum_Loc = Ident_1;
        }
    } while (Enum_Loc != Ident_1);
}

void Proc_3(Rec_Pointer *Ptr_Ref_Par) {
    if (Ptr_Glob != 0) {
        *Ptr_Ref_Par = Ptr_Glob->Ptr_Comp;
    }
    Proc_7(10, Int_Glob, &Ptr_Glob->variant.var_1.Int_Comp);
}

void Proc_4(void) {
    Boolean Bool_Loc = Ch_1_Glob == 'A';
    Bool_Loc |= Bool_Glob;
    Ch_2_Glob = 'B';
}

void Proc_5(void) {
    Ch_1_Glob = 'A';
    Bool_Glob = 0; // false
}

void Proc_6(Enumeration Enum_Val_Par, Enumeration *Enum_Ref_Par) {
    *Enum_Ref_Par = Enum_Val_Par;
    if (!Func_3(Enum_Val_Par)) {
        *Enum_Ref_Par = Ident_4;
    }
    
    switch (Enum_Val_Par) {
        case Ident_1:
            *Enum_Ref_Par = Ident_1;
            break;
        case Ident_2:
            if (Int_Glob > 100) {
                *Enum_Ref_Par = Ident_1;
            } else {
                *Enum_Ref_Par = Ident_4;
            }
            break;
        case Ident_3:
            *Enum_Ref_Par = Ident_2;
            break;
        case Ident_4:
            break;
        case Ident_5:
            *Enum_Ref_Par = Ident_3;
            break;
    }
}

void Proc_7(One_Fifty Int_1_Par_Val, One_Fifty Int_2_Par_Val, One_Fifty *Int_Par_Ref) {
    One_Fifty Int_Loc = Int_1_Par_Val + 2;
    *Int_Par_Ref = Int_2_Par_Val + Int_Loc;
}

void Proc_8(Arr_1_Dim Arr_1_Par_Ref, Arr_2_Dim Arr_2_Par_Ref, int Int_1_Par_Val, int Int_2_Par_Val) {
    One_Fifty Int_Index = Int_1_Par_Val + 5;
    
    Arr_1_Par_Ref[Int_Index] = Int_2_Par_Val;
    Arr_1_Par_Ref[Int_Index+1] = Arr_1_Par_Ref[Int_Index];
    Arr_1_Par_Ref[Int_Index+30] = Int_Index;
    
    for (Int_Index = Int_Index; Int_Index <= Int_Index+1; ++Int_Index) {
        Arr_2_Par_Ref[Int_Index][Int_Index-1] = Int_Index;
    }
    
    Arr_2_Par_Ref[Int_Index][Int_Index-1] += 1;
    Arr_2_Par_Ref[Int_1_Par_Val][Int_Index-1] = Arr_2_Par_Ref[Int_Index][Int_Index-1] + Int_1_Par_Val;
}

Enumeration Func_1(Capital_Letter Ch_1_Par_Val, Capital_Letter Ch_2_Par_Val) {
    Capital_Letter Ch_1_Loc = Ch_1_Par_Val;
    Capital_Letter Ch_2_Loc = Ch_1_Loc;
    
    if (Ch_2_Loc != Ch_2_Par_Val) {
        return Ident_1;
    } else {
        Ch_1_Glob = Ch_1_Loc;
        return Ident_2;
    }
}

Boolean Func_2(Str_30 Str_1_Par_Ref, Str_30 Str_2_Par_Ref) {
    One_Thirty Int_Loc = 2;
    Capital_Letter Ch_Loc = 'A';

    while (Int_Loc <= 2) {
        if (Func_1(Str_1_Par_Ref[Int_Loc], Str_2_Par_Ref[Int_Loc+1]) == Ident_1) {
            Ch_Loc = 'A';
            Int_Loc += 1;
        }
    }
    
    if (Ch_Loc >= 'W' && Ch_Loc < 'Z') {
        Int_Loc = 7;
    }
    
    if (Ch_Loc == 'R') {
        return 1; // true
    } else {
        if (Str_Comp(Str_1_Par_Ref, Str_2_Par_Ref) > 0) {
            Int_Loc += 7;
            Int_Glob = Int_Loc;
            return 1; // true
        } else {
            return 0; // false
        }
    }
}

Boolean Func_3(Enumeration Enum_Par_Val) {
    Enumeration Enum_Loc = Enum_Par_Val;
    
    if (Enum_Loc == Ident_3) {
        return 1; // true
    } else {
        return 0; // false
    }
} 