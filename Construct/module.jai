

#module_parameters(VERBOSE := false, ERR_ON_POINTER := false);


#scope_module
#import "Basic";

get_type_string :: (info: *Type_Info) -> string {
    if info.type == {
    case .INTEGER;
        int_info := cast(*Type_Info_Integer)info;
        if int_info.signed {
            if int_info.runtime_size == {
            case 1; return "s8";
            case 2; return "s16";
            case 4; return "s32";
            case 8; return "s64";
            }
        } else {
            if int_info.runtime_size == {
            case 1; return "u8";
            case 2; return "u16";
            case 4; return "u32";
            case 8; return "u64";
            }
        }
    case .FLOAT;
        float_info := cast(*Type_Info_Float)info;
        if float_info.runtime_size == {
        case 4; return "float32";
        case 8; return "float64";
        }
    case .BOOL;
        return "bool";
    case .ENUM;
        enum_info := cast(*Type_Info_Enum)info;
        return enum_info.name;
    case .STRUCT;
        struct_info := cast(*Type_Info_Struct)info;

        builder : String_Builder;
        init_string_builder(*builder);
        defer free_buffers(*builder);

        print_to_builder(*builder, "%", struct_info.name);
        if struct_info.polymorph_source_struct != null {
            append(*builder, "(");
            p_do_offset = false;
            for struct_info.specified_parameters {
                // #if VERBOSE print("parameters    % : %\n", it.name, <<it.type);
                parse_bytes(*builder, it.type, struct_info.constant_storage_buffer + it.offset_into_constant_storage, "");
                if it_index != struct_info.specified_parameters.count-1 then append(*builder, ", ");
            }
            append(*builder, ")");
            p_do_offset = true;
        }

        return builder_to_string(*builder);
    }
    return "";
}

p_offset : int = 0;
p_do_offset : bool = true;
print_offset :: (builder: *String_Builder) #expand {
    if !p_do_offset then return;
    for 0..p_offset-1 {
        append(builder, " ");
    }
}

parse_bytes :: (builder: *String_Builder, info: *Type_Info, val: *u8, end: string = ", ") {
    print_offset(builder);

    if info.type == {
    case .INTEGER;
        int_info := cast(*Type_Info_Integer)info;
        if int_info.signed {
            if int_info.runtime_size == {
            case 1; print_to_builder(builder, "%", <<(cast(*s8 )val));
            case 2; print_to_builder(builder, "%", <<(cast(*s16)val));
            case 4; print_to_builder(builder, "%", <<(cast(*s32)val));
            case 8; print_to_builder(builder, "%", <<(cast(*s64)val));
            }
        } else {
            if int_info.runtime_size == {
            case 1; print_to_builder(builder, "%", <<(cast(*u8 )val));
            case 2; print_to_builder(builder, "%", <<(cast(*u16)val));
            case 4; print_to_builder(builder, "%", <<(cast(*u32)val));
            case 8; print_to_builder(builder, "%", <<(cast(*u64)val));
            }
        }
    case .FLOAT;
        float_info := cast(*Type_Info_Float)info;
        if float_info.runtime_size == {
        case 4; print_to_builder(builder, "%", <<(cast(*float32)val));
        case 8; print_to_builder(builder, "%", <<(cast(*float64)val));
        }
    case .BOOL;
        print_to_builder(builder, "%", <<(cast(*bool)val));
    case .STRING;
        print_to_builder(builder, "\"%\"", <<(cast(*string)val));
    case .TYPE;
        print_to_builder(builder, "%", <<(cast(*Type)val));
    case .ENUM;
        enum_info := cast(*Type_Info_Enum)info;

        name : string = ---;
        for enum_info.values {
            if it == <<(cast(*s64)val) {
                name = enum_info.names[it_index];
                break;
            }
        }

        print_to_builder(builder, "%.%", enum_info.name, name);
    case .ARRAY;
        array_info := cast(*Type_Info_Array)info;
        print_to_builder(builder, "%.[", get_type_string(array_info.element_type));

        if array_info.element_type.type == .STRUCT {
            append(builder, "\n");
            p_offset += 4;
        } else {
            p_do_offset = false;
        }
        
        if array_info.array_type == .FIXED {
            #if VERBOSE print("there are % elements in the FIXED array\n", array_info.array_count);
            #if VERBOSE print("elements are %\n", <<array_info.element_type);
            offset := 0;
            for 0..array_info.array_count-1 {
                parse_bytes(builder, array_info.element_type, val + offset, "");
                if it != array_info.array_count-1 then append(builder, ", ");
                offset += array_info.element_type.runtime_size;
            }
        } else {
            view := cast(*Array_View_64)val;
            #if VERBOSE print("view = %\n", <<view);

            offset := 0;
            for 0..view.count-1 {
                parse_bytes(builder, array_info.element_type, view.data + offset, "");
                if it != view.count-1 then append(builder, ", ");
                offset += array_info.element_type.runtime_size;

                if array_info.element_type.type == .STRUCT {
                    append(builder, "\n");
                }
            }
        }

        if array_info.element_type.type == .STRUCT {
            p_offset -= 4;
            print_offset(builder);
        } else {
            p_do_offset = true;
        }
        
        append(builder, "]");
    case .STRUCT;
        struct_info := cast(*Type_Info_Struct)info;
        #if VERBOSE print("struct_info = %\n", <<struct_info);

        append(builder, get_type_string(struct_info));
        append(builder, ".{");
        if struct_info.members.count > 2 {
            append(builder, "\n");
        } else p_do_offset = false;

        p_offset += 4;

        for struct_info.members {
            #if VERBOSE print("member type = %\n", <<it.type);
            parse_bytes(builder, it.type, val + it.offset_in_bytes, "");
            if it_index != struct_info.members.count-1 then append(builder, ", ");
            if struct_info.members.count > 2 then append(builder, "\n");
        }

        p_offset -= 4;

        print_offset(builder);
        append(builder, "}");
        p_do_offset = true;
    case .POINTER;
        #if ERR_ON_POINTER
            assert(false, "Cannot construct compile-time constant variable with pointers! (yet?)\n");
        append(builder, "null");
    }

    append(builder, end);
}


#scope_export
construct :: (val: $T, end: string = ";\n") -> string {
    builder : String_Builder;
    init_string_builder(*builder);
    defer free_buffers(*builder);

    info := type_info(T);

    #if VERBOSE {
        print("T              = %\n", T);
        print("val            = %\n", val);
        print("<<type_info(T) = %\n", <<info);
        print("----------------------------------\n");
    }

    parse_bytes(*builder, info, cast(*u8)(*val), ";\n");

    res := builder_to_string(*builder);
    #if VERBOSE print("%\n", res);
    return res;
}
