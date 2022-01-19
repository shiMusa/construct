#import "Basic";
#import "Construct" (VERBOSE = true);

Foo :: struct {
    val: int;
    arr: [6]float64;
}

Bar :: struct(T: Type) {
    val: T;
}


Options :: enum {
    ON;
    OFF;
    UNDECIDED;
}

Results :: enum u8 {
    OK;
    ERROR;
    WARNING;
    MAYBE;
    PROBABLY;
    NOT;
}

Complex :: struct(T: Type, N: int) {
    vals: [N]T;
    doit: Options = .UNDECIDED;
    msg: string = "Hello World";
    view: []u8;
}


main :: () {
    t_int : u8 : #insert #run construct(42);
    print("%\n", t_int);
    
    t_float : float64 : #insert #run construct(3.141);
    print("%\n", t_float);
    
    t_bool : bool : #insert #run construct(false);
    print("%\n", t_bool);
    
    t_string : string : #insert #run construct("Hello World");
    print("%\n", t_string);

    t_arr_i :: #insert #run construct(u8.[5,4,3,2,1]);
    print("%\n", t_arr_i);

    t_arr_i2 :: #insert #run () -> string {
        res := NewArray(5, u8, false);
        defer array_free(res);
        for 0..4 { res[it] = cast(u8)it; }
        return construct(res);
    }();
    print("%\n", t_arr_i2);

    t_arr_f :: #insert #run construct(float64.[5.0,4.0,3.0,2.0,1.0]);
    print("%\n", t_arr_f);

    t_struct :: #insert #run () -> string {
        f : Foo = ---;
        f.val = 42;
        f.arr = float64.[1.0,2.0,3.0,4.0,5.0,6.0];
        return construct(f);
    }();
    print("%\n", t_struct);

    t_poly_struct :: #insert #run () -> string {
        b : Bar(s8) = ---;
        b.val = -2;
        return construct(b);
    }();
    print("%\n", t_poly_struct);

    t_enum :: #insert #run () -> string {
        e := Options.OFF;
        return construct(e);
    }();
    print("%\n", t_enum);

    t_enum_u8 :: #insert #run () -> string {
        e := Results.MAYBE;
        return construct(e);
    }();
    print("%\n", t_enum_u8);

    t_compelx :: #insert #run () -> string {
        c : Complex(s16, 4);
        c.vals = s16.[-2,-1,0,1];
        c.doit = Options.ON;

        data := NewArray(3, u8, false);
        data[0] = #char "a";
        data[1] = #char "A";
        data[2] = #char "0";
        c.view = data;

        return construct(c);
    }();
    print("%\n", t_compelx);

    T :: float64;
    // ! It is important to specify `T` as the type of `t_outer`, 
    // ! otherwise it will be interpreted as `float32` (the default).
    t_outer : T : #insert #run () -> string {
        x : T = 123.456;
        return construct(x);
    }();
    print("%\n", t_outer);
}