const std = @import("std");

pub const DiagnosticMessage = struct {
    message: []const u8,
    category: []const u8,
    code: []const u8,
};
pub const unterminated_string_literal = DiagnosticMessage{
    .message = "Unterminated string literal.",
    .category = "Error",
    .code = "1002",
};
pub const identifier_expected = DiagnosticMessage{
    .message = "Identifier expected.",
    .category = "Error",
    .code = "1003",
};
pub const ARG_expected = DiagnosticMessage{
    .message = "'{0s}' expected.",
    .category = "Error",
    .code = "1005",
};
pub const a_file_cannot_have_a_reference_to_itself = DiagnosticMessage{
    .message = "A file cannot have a reference to itself.",
    .category = "Error",
    .code = "1006",
};
pub const the_parser_expected_to_find_a_ARG_to_match_the_ARG_token_here = DiagnosticMessage{
    .message = "The parser expected to find a '{1s}' to match the '{0s}' token here.",
    .category = "Error",
    .code = "1007",
};
pub const trailing_comma_not_allowed = DiagnosticMessage{
    .message = "Trailing comma not allowed.",
    .category = "Error",
    .code = "1009",
};
pub const expected = DiagnosticMessage{
    .message = "'*/' expected.",
    .category = "Error",
    .code = "1010",
};
pub const an_element_access_expression_should_take_an_argument = DiagnosticMessage{
    .message = "An element access expression should take an argument.",
    .category = "Error",
    .code = "1011",
};
pub const unexpected_token = DiagnosticMessage{
    .message = "Unexpected token.",
    .category = "Error",
    .code = "1012",
};
pub const a_rest_parameter_or_binding_pattern_may_not_have_a_trailing_comma = DiagnosticMessage{
    .message = "A rest parameter or binding pattern may not have a trailing comma.",
    .category = "Error",
    .code = "1013",
};
pub const a_rest_parameter_must_be_last_in_a_parameter_list = DiagnosticMessage{
    .message = "A rest parameter must be last in a parameter list.",
    .category = "Error",
    .code = "1014",
};
pub const parameter_cannot_have_question_mark_and_initializer = DiagnosticMessage{
    .message = "Parameter cannot have question mark and initializer.",
    .category = "Error",
    .code = "1015",
};
pub const a_required_parameter_cannot_follow_an_optional_parameter = DiagnosticMessage{
    .message = "A required parameter cannot follow an optional parameter.",
    .category = "Error",
    .code = "1016",
};
pub const an_index_signature_cannot_have_a_rest_parameter = DiagnosticMessage{
    .message = "An index signature cannot have a rest parameter.",
    .category = "Error",
    .code = "1017",
};
pub const an_index_signature_parameter_cannot_have_an_accessibility_modifier = DiagnosticMessage{
    .message = "An index signature parameter cannot have an accessibility modifier.",
    .category = "Error",
    .code = "1018",
};
pub const an_index_signature_parameter_cannot_have_a_question_mark = DiagnosticMessage{
    .message = "An index signature parameter cannot have a question mark.",
    .category = "Error",
    .code = "1019",
};
pub const an_index_signature_parameter_cannot_have_an_initializer = DiagnosticMessage{
    .message = "An index signature parameter cannot have an initializer.",
    .category = "Error",
    .code = "1020",
};
pub const an_index_signature_must_have_a_type_annotation = DiagnosticMessage{
    .message = "An index signature must have a type annotation.",
    .category = "Error",
    .code = "1021",
};
pub const an_index_signature_parameter_must_have_a_type_annotation = DiagnosticMessage{
    .message = "An index signature parameter must have a type annotation.",
    .category = "Error",
    .code = "1022",
};
pub const readonly_modifier_can_only_appear_on_a_property_declaration_or_index_signature = DiagnosticMessage{
    .message = "'readonly' modifier can only appear on a property declaration or index signature.",
    .category = "Error",
    .code = "1024",
};
pub const an_index_signature_cannot_have_a_trailing_comma = DiagnosticMessage{
    .message = "An index signature cannot have a trailing comma.",
    .category = "Error",
    .code = "1025",
};
pub const accessibility_modifier_already_seen = DiagnosticMessage{
    .message = "Accessibility modifier already seen.",
    .category = "Error",
    .code = "1028",
};
pub const ARG_modifier_must_precede_ARG_modifier = DiagnosticMessage{
    .message = "'{0s}' modifier must precede '{1s}' modifier.",
    .category = "Error",
    .code = "1029",
};
pub const ARG_modifier_already_seen = DiagnosticMessage{
    .message = "'{0s}' modifier already seen.",
    .category = "Error",
    .code = "1030",
};
pub const ARG_modifier_cannot_appear_on_class_elements_of_this_kind = DiagnosticMessage{
    .message = "'{0s}' modifier cannot appear on class elements of this kind.",
    .category = "Error",
    .code = "1031",
};
pub const super_must_be_followed_by_an_argument_list_or_member_access = DiagnosticMessage{
    .message = "'super' must be followed by an argument list or member access.",
    .category = "Error",
    .code = "1034",
};
pub const only_ambient_modules_can_use_quoted_names = DiagnosticMessage{
    .message = "Only ambient modules can use quoted names.",
    .category = "Error",
    .code = "1035",
};
pub const statements_are_not_allowed_in_ambient_contexts = DiagnosticMessage{
    .message = "Statements are not allowed in ambient contexts.",
    .category = "Error",
    .code = "1036",
};
pub const a_declare_modifier_cannot_be_used_in_an_already_ambient_context = DiagnosticMessage{
    .message = "A 'declare' modifier cannot be used in an already ambient context.",
    .category = "Error",
    .code = "1038",
};
pub const initializers_are_not_allowed_in_ambient_contexts = DiagnosticMessage{
    .message = "Initializers are not allowed in ambient contexts.",
    .category = "Error",
    .code = "1039",
};
pub const ARG_modifier_cannot_be_used_in_an_ambient_context = DiagnosticMessage{
    .message = "'{0s}' modifier cannot be used in an ambient context.",
    .category = "Error",
    .code = "1040",
};
pub const ARG_modifier_cannot_be_used_here = DiagnosticMessage{
    .message = "'{0s}' modifier cannot be used here.",
    .category = "Error",
    .code = "1042",
};
pub const ARG_modifier_cannot_appear_on_a_module_or_namespace_element = DiagnosticMessage{
    .message = "'{0s}' modifier cannot appear on a module or namespace element.",
    .category = "Error",
    .code = "1044",
};
pub const top_level_declarations_in_d_ts_files_must_start_with_either_a_declare_or_export_modifier = DiagnosticMessage{
    .message = "Top-level declarations in .d.ts files must start with either a 'declare' or 'export' modifier.",
    .category = "Error",
    .code = "1046",
};
pub const a_rest_parameter_cannot_be_optional = DiagnosticMessage{
    .message = "A rest parameter cannot be optional.",
    .category = "Error",
    .code = "1047",
};
pub const a_rest_parameter_cannot_have_an_initializer = DiagnosticMessage{
    .message = "A rest parameter cannot have an initializer.",
    .category = "Error",
    .code = "1048",
};
pub const a_set_accessor_must_have_exactly_one_parameter = DiagnosticMessage{
    .message = "A 'set' accessor must have exactly one parameter.",
    .category = "Error",
    .code = "1049",
};
pub const a_set_accessor_cannot_have_an_optional_parameter = DiagnosticMessage{
    .message = "A 'set' accessor cannot have an optional parameter.",
    .category = "Error",
    .code = "1051",
};
pub const a_set_accessor_parameter_cannot_have_an_initializer = DiagnosticMessage{
    .message = "A 'set' accessor parameter cannot have an initializer.",
    .category = "Error",
    .code = "1052",
};
pub const a_set_accessor_cannot_have_rest_parameter = DiagnosticMessage{
    .message = "A 'set' accessor cannot have rest parameter.",
    .category = "Error",
    .code = "1053",
};
pub const a_get_accessor_cannot_have_parameters = DiagnosticMessage{
    .message = "A 'get' accessor cannot have parameters.",
    .category = "Error",
    .code = "1054",
};
pub const type_ARG_is_not_a_valid_async_function_return_type_in_es5_because_it_does_not_refer_to_a_promise_compatible_constructor_value = DiagnosticMessage{
    .message = "Type '{0s}' is not a valid async function return type in ES5 because it does not refer to a Promise-compatible constructor value.",
    .category = "Error",
    .code = "1055",
};
pub const accessors_are_only_available_when_targeting_ecmascript_5_and_higher = DiagnosticMessage{
    .message = "Accessors are only available when targeting ECMAScript 5 and higher.",
    .category = "Error",
    .code = "1056",
};
pub const the_return_type_of_an_async_function_must_either_be_a_valid_promise_or_must_not_contain_a_callable_then_member = DiagnosticMessage{
    .message = "The return type of an async function must either be a valid promise or must not contain a callable 'then' member.",
    .category = "Error",
    .code = "1058",
};
pub const a_promise_must_have_a_then_method = DiagnosticMessage{
    .message = "A promise must have a 'then' method.",
    .category = "Error",
    .code = "1059",
};
pub const the_first_parameter_of_the_then_method_of_a_promise_must_be_a_callback = DiagnosticMessage{
    .message = "The first parameter of the 'then' method of a promise must be a callback.",
    .category = "Error",
    .code = "1060",
};
pub const enum_member_must_have_initializer = DiagnosticMessage{
    .message = "Enum member must have initializer.",
    .category = "Error",
    .code = "1061",
};
pub const type_is_referenced_directly_or_indirectly_in_the_fulfillment_callback_of_its_own_then_method = DiagnosticMessage{
    .message = "Type is referenced directly or indirectly in the fulfillment callback of its own 'then' method.",
    .category = "Error",
    .code = "1062",
};
pub const an_export_assignment_cannot_be_used_in_a_namespace = DiagnosticMessage{
    .message = "An export assignment cannot be used in a namespace.",
    .category = "Error",
    .code = "1063",
};
pub const the_return_type_of_an_async_function_or_method_must_be_the_global_promise_t_type_did_you_mean_to_write_promise_ARG = DiagnosticMessage{
    .message = "The return type of an async function or method must be the global Promise<T> type. Did you mean to write 'Promise<{0s}>'?",
    .category = "Error",
    .code = "1064",
};
pub const the_return_type_of_an_async_function_or_method_must_be_the_global_promise_t_type = DiagnosticMessage{
    .message = "The return type of an async function or method must be the global Promise<T> type.",
    .category = "Error",
    .code = "1065",
};
pub const in_ambient_enum_declarations_member_initializer_must_be_constant_expression = DiagnosticMessage{
    .message = "In ambient enum declarations member initializer must be constant expression.",
    .category = "Error",
    .code = "1066",
};
pub const unexpected_token_a_constructor_method_accessor_or_property_was_expected = DiagnosticMessage{
    .message = "Unexpected token. A constructor, method, accessor, or property was expected.",
    .category = "Error",
    .code = "1068",
};
pub const unexpected_token_a_type_parameter_name_was_expected_without_curly_braces = DiagnosticMessage{
    .message = "Unexpected token. A type parameter name was expected without curly braces.",
    .category = "Error",
    .code = "1069",
};
pub const ARG_modifier_cannot_appear_on_a_type_member = DiagnosticMessage{
    .message = "'{0s}' modifier cannot appear on a type member.",
    .category = "Error",
    .code = "1070",
};
pub const ARG_modifier_cannot_appear_on_an_index_signature = DiagnosticMessage{
    .message = "'{0s}' modifier cannot appear on an index signature.",
    .category = "Error",
    .code = "1071",
};
pub const a_ARG_modifier_cannot_be_used_with_an_import_declaration = DiagnosticMessage{
    .message = "A '{0s}' modifier cannot be used with an import declaration.",
    .category = "Error",
    .code = "1079",
};
pub const invalid_reference_directive_syntax = DiagnosticMessage{
    .message = "Invalid 'reference' directive syntax.",
    .category = "Error",
    .code = "1084",
};
pub const ARG_modifier_cannot_appear_on_a_constructor_declaration = DiagnosticMessage{
    .message = "'{0s}' modifier cannot appear on a constructor declaration.",
    .category = "Error",
    .code = "1089",
};
pub const ARG_modifier_cannot_appear_on_a_parameter = DiagnosticMessage{
    .message = "'{0s}' modifier cannot appear on a parameter.",
    .category = "Error",
    .code = "1090",
};
pub const only_a_single_variable_declaration_is_allowed_in_a_for_in_statement = DiagnosticMessage{
    .message = "Only a single variable declaration is allowed in a 'for...in' statement.",
    .category = "Error",
    .code = "1091",
};
pub const type_parameters_cannot_appear_on_a_constructor_declaration = DiagnosticMessage{
    .message = "Type parameters cannot appear on a constructor declaration.",
    .category = "Error",
    .code = "1092",
};
pub const type_annotation_cannot_appear_on_a_constructor_declaration = DiagnosticMessage{
    .message = "Type annotation cannot appear on a constructor declaration.",
    .category = "Error",
    .code = "1093",
};
pub const an_accessor_cannot_have_type_parameters = DiagnosticMessage{
    .message = "An accessor cannot have type parameters.",
    .category = "Error",
    .code = "1094",
};
pub const a_set_accessor_cannot_have_a_return_type_annotation = DiagnosticMessage{
    .message = "A 'set' accessor cannot have a return type annotation.",
    .category = "Error",
    .code = "1095",
};
pub const an_index_signature_must_have_exactly_one_parameter = DiagnosticMessage{
    .message = "An index signature must have exactly one parameter.",
    .category = "Error",
    .code = "1096",
};
pub const ARG_list_cannot_be_empty = DiagnosticMessage{
    .message = "'{0s}' list cannot be empty.",
    .category = "Error",
    .code = "1097",
};
pub const type_parameter_list_cannot_be_empty = DiagnosticMessage{
    .message = "Type parameter list cannot be empty.",
    .category = "Error",
    .code = "1098",
};
pub const type_argument_list_cannot_be_empty = DiagnosticMessage{
    .message = "Type argument list cannot be empty.",
    .category = "Error",
    .code = "1099",
};
pub const invalid_use_of_ARG_in_strict_mode = DiagnosticMessage{
    .message = "Invalid use of '{0s}' in strict mode.",
    .category = "Error",
    .code = "1100",
};
pub const with_statements_are_not_allowed_in_strict_mode = DiagnosticMessage{
    .message = "'with' statements are not allowed in strict mode.",
    .category = "Error",
    .code = "1101",
};
pub const delete_cannot_be_called_on_an_identifier_in_strict_mode = DiagnosticMessage{
    .message = "'delete' cannot be called on an identifier in strict mode.",
    .category = "Error",
    .code = "1102",
};
pub const for_await_loops_are_only_allowed_within_async_functions_and_at_the_top_levels_of_modules = DiagnosticMessage{
    .message = "'for await' loops are only allowed within async functions and at the top levels of modules.",
    .category = "Error",
    .code = "1103",
};
pub const a_continue_statement_can_only_be_used_within_an_enclosing_iteration_statement = DiagnosticMessage{
    .message = "A 'continue' statement can only be used within an enclosing iteration statement.",
    .category = "Error",
    .code = "1104",
};
pub const a_break_statement_can_only_be_used_within_an_enclosing_iteration_or_switch_statement = DiagnosticMessage{
    .message = "A 'break' statement can only be used within an enclosing iteration or switch statement.",
    .category = "Error",
    .code = "1105",
};
pub const the_left_hand_side_of_a_for_of_statement_may_not_be_async = DiagnosticMessage{
    .message = "The left-hand side of a 'for...of' statement may not be 'async'.",
    .category = "Error",
    .code = "1106",
};
pub const jump_target_cannot_cross_function_boundary = DiagnosticMessage{
    .message = "Jump target cannot cross function boundary.",
    .category = "Error",
    .code = "1107",
};
pub const a_return_statement_can_only_be_used_within_a_function_body = DiagnosticMessage{
    .message = "A 'return' statement can only be used within a function body.",
    .category = "Error",
    .code = "1108",
};
pub const expression_expected = DiagnosticMessage{
    .message = "Expression expected.",
    .category = "Error",
    .code = "1109",
};
pub const type_expected = DiagnosticMessage{
    .message = "Type expected.",
    .category = "Error",
    .code = "1110",
};
pub const private_field_ARG_must_be_declared_in_an_enclosing_class = DiagnosticMessage{
    .message = "Private field '{0s}' must be declared in an enclosing class.",
    .category = "Error",
    .code = "1111",
};
pub const a_default_clause_cannot_appear_more_than_once_in_a_switch_statement = DiagnosticMessage{
    .message = "A 'default' clause cannot appear more than once in a 'switch' statement.",
    .category = "Error",
    .code = "1113",
};
pub const duplicate_label_ARG = DiagnosticMessage{
    .message = "Duplicate label '{0s}'.",
    .category = "Error",
    .code = "1114",
};
pub const a_continue_statement_can_only_jump_to_a_label_of_an_enclosing_iteration_statement = DiagnosticMessage{
    .message = "A 'continue' statement can only jump to a label of an enclosing iteration statement.",
    .category = "Error",
    .code = "1115",
};
pub const a_break_statement_can_only_jump_to_a_label_of_an_enclosing_statement = DiagnosticMessage{
    .message = "A 'break' statement can only jump to a label of an enclosing statement.",
    .category = "Error",
    .code = "1116",
};
pub const an_object_literal_cannot_have_multiple_properties_with_the_same_name = DiagnosticMessage{
    .message = "An object literal cannot have multiple properties with the same name.",
    .category = "Error",
    .code = "1117",
};
pub const an_object_literal_cannot_have_multiple_get_set_accessors_with_the_same_name = DiagnosticMessage{
    .message = "An object literal cannot have multiple get/set accessors with the same name.",
    .category = "Error",
    .code = "1118",
};
pub const an_object_literal_cannot_have_property_and_accessor_with_the_same_name = DiagnosticMessage{
    .message = "An object literal cannot have property and accessor with the same name.",
    .category = "Error",
    .code = "1119",
};
pub const an_export_assignment_cannot_have_modifiers = DiagnosticMessage{
    .message = "An export assignment cannot have modifiers.",
    .category = "Error",
    .code = "1120",
};
pub const octal_literals_are_not_allowed_use_the_syntax_ARG = DiagnosticMessage{
    .message = "Octal literals are not allowed. Use the syntax '{0s}'.",
    .category = "Error",
    .code = "1121",
};
pub const variable_declaration_list_cannot_be_empty = DiagnosticMessage{
    .message = "Variable declaration list cannot be empty.",
    .category = "Error",
    .code = "1123",
};
pub const digit_expected = DiagnosticMessage{
    .message = "Digit expected.",
    .category = "Error",
    .code = "1124",
};
pub const hexadecimal_digit_expected = DiagnosticMessage{
    .message = "Hexadecimal digit expected.",
    .category = "Error",
    .code = "1125",
};
pub const unexpected_end_of_text = DiagnosticMessage{
    .message = "Unexpected end of text.",
    .category = "Error",
    .code = "1126",
};
pub const invalid_character = DiagnosticMessage{
    .message = "Invalid character.",
    .category = "Error",
    .code = "1127",
};
pub const declaration_or_statement_expected = DiagnosticMessage{
    .message = "Declaration or statement expected.",
    .category = "Error",
    .code = "1128",
};
pub const statement_expected = DiagnosticMessage{
    .message = "Statement expected.",
    .category = "Error",
    .code = "1129",
};
pub const case_or_default_expected = DiagnosticMessage{
    .message = "'case' or 'default' expected.",
    .category = "Error",
    .code = "1130",
};
pub const property_or_signature_expected = DiagnosticMessage{
    .message = "Property or signature expected.",
    .category = "Error",
    .code = "1131",
};
pub const enum_member_expected = DiagnosticMessage{
    .message = "Enum member expected.",
    .category = "Error",
    .code = "1132",
};
pub const variable_declaration_expected = DiagnosticMessage{
    .message = "Variable declaration expected.",
    .category = "Error",
    .code = "1134",
};
pub const argument_expression_expected = DiagnosticMessage{
    .message = "Argument expression expected.",
    .category = "Error",
    .code = "1135",
};
pub const property_assignment_expected = DiagnosticMessage{
    .message = "Property assignment expected.",
    .category = "Error",
    .code = "1136",
};
pub const expression_or_comma_expected = DiagnosticMessage{
    .message = "Expression or comma expected.",
    .category = "Error",
    .code = "1137",
};
pub const parameter_declaration_expected = DiagnosticMessage{
    .message = "Parameter declaration expected.",
    .category = "Error",
    .code = "1138",
};
pub const type_parameter_declaration_expected = DiagnosticMessage{
    .message = "Type parameter declaration expected.",
    .category = "Error",
    .code = "1139",
};
pub const type_argument_expected = DiagnosticMessage{
    .message = "Type argument expected.",
    .category = "Error",
    .code = "1140",
};
pub const string_literal_expected = DiagnosticMessage{
    .message = "String literal expected.",
    .category = "Error",
    .code = "1141",
};
pub const line_break_not_permitted_here = DiagnosticMessage{
    .message = "Line break not permitted here.",
    .category = "Error",
    .code = "1142",
};
pub const or_expected = DiagnosticMessage{
    .message = "'{{' or ';' expected.",
    .category = "Error",
    .code = "1144",
};
pub const or_jsx_element_expected = DiagnosticMessage{
    .message = "'{{' or JSX element expected.",
    .category = "Error",
    .code = "1145",
};
pub const declaration_expected = DiagnosticMessage{
    .message = "Declaration expected.",
    .category = "Error",
    .code = "1146",
};
pub const import_declarations_in_a_namespace_cannot_reference_a_module = DiagnosticMessage{
    .message = "Import declarations in a namespace cannot reference a module.",
    .category = "Error",
    .code = "1147",
};
pub const cannot_use_imports_exports_or_module_augmentations_when_module_is_none = DiagnosticMessage{
    .message = "Cannot use imports, exports, or module augmentations when '--module' is 'none'.",
    .category = "Error",
    .code = "1148",
};
pub const file_name_ARG_differs_from_already_included_file_name_ARG_only_in_casing = DiagnosticMessage{
    .message = "File name '{0s}' differs from already included file name '{1s}' only in casing.",
    .category = "Error",
    .code = "1149",
};
pub const ARG_declarations_must_be_initialized = DiagnosticMessage{
    .message = "'{0s}' declarations must be initialized.",
    .category = "Error",
    .code = "1155",
};
pub const ARG_declarations_can_only_be_declared_inside_a_block = DiagnosticMessage{
    .message = "'{0s}' declarations can only be declared inside a block.",
    .category = "Error",
    .code = "1156",
};
pub const unterminated_template_literal = DiagnosticMessage{
    .message = "Unterminated template literal.",
    .category = "Error",
    .code = "1160",
};
pub const unterminated_regular_expression_literal = DiagnosticMessage{
    .message = "Unterminated regular expression literal.",
    .category = "Error",
    .code = "1161",
};
pub const an_object_member_cannot_be_declared_optional = DiagnosticMessage{
    .message = "An object member cannot be declared optional.",
    .category = "Error",
    .code = "1162",
};
pub const a_yield_expression_is_only_allowed_in_a_generator_body = DiagnosticMessage{
    .message = "A 'yield' expression is only allowed in a generator body.",
    .category = "Error",
    .code = "1163",
};
pub const computed_property_names_are_not_allowed_in_enums = DiagnosticMessage{
    .message = "Computed property names are not allowed in enums.",
    .category = "Error",
    .code = "1164",
};
pub const a_computed_property_name_in_an_ambient_context_must_refer_to_an_expression_whose_type_is_a_literal_type_or_a_unique_symbol_type = DiagnosticMessage{
    .message = "A computed property name in an ambient context must refer to an expression whose type is a literal type or a 'unique symbol' type.",
    .category = "Error",
    .code = "1165",
};
pub const a_computed_property_name_in_a_class_property_declaration_must_have_a_simple_literal_type_or_a_unique_symbol_type = DiagnosticMessage{
    .message = "A computed property name in a class property declaration must have a simple literal type or a 'unique symbol' type.",
    .category = "Error",
    .code = "1166",
};
pub const a_computed_property_name_in_a_method_overload_must_refer_to_an_expression_whose_type_is_a_literal_type_or_a_unique_symbol_type = DiagnosticMessage{
    .message = "A computed property name in a method overload must refer to an expression whose type is a literal type or a 'unique symbol' type.",
    .category = "Error",
    .code = "1168",
};
pub const a_computed_property_name_in_an_interface_must_refer_to_an_expression_whose_type_is_a_literal_type_or_a_unique_symbol_type = DiagnosticMessage{
    .message = "A computed property name in an interface must refer to an expression whose type is a literal type or a 'unique symbol' type.",
    .category = "Error",
    .code = "1169",
};
pub const a_computed_property_name_in_a_type_literal_must_refer_to_an_expression_whose_type_is_a_literal_type_or_a_unique_symbol_type = DiagnosticMessage{
    .message = "A computed property name in a type literal must refer to an expression whose type is a literal type or a 'unique symbol' type.",
    .category = "Error",
    .code = "1170",
};
pub const a_comma_expression_is_not_allowed_in_a_computed_property_name = DiagnosticMessage{
    .message = "A comma expression is not allowed in a computed property name.",
    .category = "Error",
    .code = "1171",
};
pub const extends_clause_already_seen = DiagnosticMessage{
    .message = "'extends' clause already seen.",
    .category = "Error",
    .code = "1172",
};
pub const extends_clause_must_precede_implements_clause = DiagnosticMessage{
    .message = "'extends' clause must precede 'implements' clause.",
    .category = "Error",
    .code = "1173",
};
pub const classes_can_only_extend_a_single_class = DiagnosticMessage{
    .message = "Classes can only extend a single class.",
    .category = "Error",
    .code = "1174",
};
pub const implements_clause_already_seen = DiagnosticMessage{
    .message = "'implements' clause already seen.",
    .category = "Error",
    .code = "1175",
};
pub const interface_declaration_cannot_have_implements_clause = DiagnosticMessage{
    .message = "Interface declaration cannot have 'implements' clause.",
    .category = "Error",
    .code = "1176",
};
pub const binary_digit_expected = DiagnosticMessage{
    .message = "Binary digit expected.",
    .category = "Error",
    .code = "1177",
};
pub const octal_digit_expected = DiagnosticMessage{
    .message = "Octal digit expected.",
    .category = "Error",
    .code = "1178",
};
pub const unexpected_token_expected = DiagnosticMessage{
    .message = "Unexpected token. '{{' expected.",
    .category = "Error",
    .code = "1179",
};
pub const property_destructuring_pattern_expected = DiagnosticMessage{
    .message = "Property destructuring pattern expected.",
    .category = "Error",
    .code = "1180",
};
pub const array_element_destructuring_pattern_expected = DiagnosticMessage{
    .message = "Array element destructuring pattern expected.",
    .category = "Error",
    .code = "1181",
};
pub const a_destructuring_declaration_must_have_an_initializer = DiagnosticMessage{
    .message = "A destructuring declaration must have an initializer.",
    .category = "Error",
    .code = "1182",
};
pub const an_implementation_cannot_be_declared_in_ambient_contexts = DiagnosticMessage{
    .message = "An implementation cannot be declared in ambient contexts.",
    .category = "Error",
    .code = "1183",
};
pub const modifiers_cannot_appear_here = DiagnosticMessage{
    .message = "Modifiers cannot appear here.",
    .category = "Error",
    .code = "1184",
};
pub const merge_conflict_marker_encountered = DiagnosticMessage{
    .message = "Merge conflict marker encountered.",
    .category = "Error",
    .code = "1185",
};
pub const a_rest_element_cannot_have_an_initializer = DiagnosticMessage{
    .message = "A rest element cannot have an initializer.",
    .category = "Error",
    .code = "1186",
};
pub const a_parameter_property_may_not_be_declared_using_a_binding_pattern = DiagnosticMessage{
    .message = "A parameter property may not be declared using a binding pattern.",
    .category = "Error",
    .code = "1187",
};
pub const only_a_single_variable_declaration_is_allowed_in_a_for_of_statement = DiagnosticMessage{
    .message = "Only a single variable declaration is allowed in a 'for...of' statement.",
    .category = "Error",
    .code = "1188",
};
pub const the_variable_declaration_of_a_for_in_statement_cannot_have_an_initializer = DiagnosticMessage{
    .message = "The variable declaration of a 'for...in' statement cannot have an initializer.",
    .category = "Error",
    .code = "1189",
};
pub const the_variable_declaration_of_a_for_of_statement_cannot_have_an_initializer = DiagnosticMessage{
    .message = "The variable declaration of a 'for...of' statement cannot have an initializer.",
    .category = "Error",
    .code = "1190",
};
pub const an_import_declaration_cannot_have_modifiers = DiagnosticMessage{
    .message = "An import declaration cannot have modifiers.",
    .category = "Error",
    .code = "1191",
};
pub const module_ARG_has_no_default_export = DiagnosticMessage{
    .message = "Module '{0s}' has no default export.",
    .category = "Error",
    .code = "1192",
};
pub const an_export_declaration_cannot_have_modifiers = DiagnosticMessage{
    .message = "An export declaration cannot have modifiers.",
    .category = "Error",
    .code = "1193",
};
pub const export_declarations_are_not_permitted_in_a_namespace = DiagnosticMessage{
    .message = "Export declarations are not permitted in a namespace.",
    .category = "Error",
    .code = "1194",
};
pub const export_does_not_re_export_a_default = DiagnosticMessage{
    .message = "'export *' does not re-export a default.",
    .category = "Error",
    .code = "1195",
};
pub const catch_clause_variable_type_annotation_must_be_any_or_unknown_if_specified = DiagnosticMessage{
    .message = "Catch clause variable type annotation must be 'any' or 'unknown' if specified.",
    .category = "Error",
    .code = "1196",
};
pub const catch_clause_variable_cannot_have_an_initializer = DiagnosticMessage{
    .message = "Catch clause variable cannot have an initializer.",
    .category = "Error",
    .code = "1197",
};
pub const an_extended_unicode_escape_value_must_be_between_0x0_and_0x10ffff_inclusive = DiagnosticMessage{
    .message = "An extended Unicode escape value must be between 0x0 and 0x10FFFF inclusive.",
    .category = "Error",
    .code = "1198",
};
pub const unterminated_unicode_escape_sequence = DiagnosticMessage{
    .message = "Unterminated Unicode escape sequence.",
    .category = "Error",
    .code = "1199",
};
pub const line_terminator_not_permitted_before_arrow = DiagnosticMessage{
    .message = "Line terminator not permitted before arrow.",
    .category = "Error",
    .code = "1200",
};
pub const import_assignment_cannot_be_used_when_targeting_ecmascript_modules_consider_using_import_as_ns_from_mod_import_ARG_from_mod_import_d_from_mod_or_another_module_format_instead = DiagnosticMessage{
    .message = "Import assignment cannot be used when targeting ECMAScript modules. Consider using 'import * as ns from \"mod\"', 'import {as} from \"mod\"', 'import d from \"mod\"', or another module format instead.",
    .category = "Error",
    .code = "1202",
};
pub const export_assignment_cannot_be_used_when_targeting_ecmascript_modules_consider_using_export_default_or_another_module_format_instead = DiagnosticMessage{
    .message = "Export assignment cannot be used when targeting ECMAScript modules. Consider using 'export default' or another module format instead.",
    .category = "Error",
    .code = "1203",
};
pub const re_exporting_a_type_when_ARG_is_enabled_requires_using_export_type = DiagnosticMessage{
    .message = "Re-exporting a type when '{0s}' is enabled requires using 'export type'.",
    .category = "Error",
    .code = "1205",
};
pub const decorators_are_not_valid_here = DiagnosticMessage{
    .message = "Decorators are not valid here.",
    .category = "Error",
    .code = "1206",
};
pub const decorators_cannot_be_applied_to_multiple_get_set_accessors_of_the_same_name = DiagnosticMessage{
    .message = "Decorators cannot be applied to multiple get/set accessors of the same name.",
    .category = "Error",
    .code = "1207",
};
pub const invalid_optional_chain_from_new_expression_did_you_mean_to_call_ARG = DiagnosticMessage{
    .message = "Invalid optional chain from new expression. Did you mean to call '{0s}()'?",
    .category = "Error",
    .code = "1209",
};
pub const code_contained_in_a_class_is_evaluated_in_javascript_s_strict_mode_which_does_not_allow_this_use_of_ARG_for_more_information_see_https_developer_mozilla_org_en_us_docs_web_javascript_reference_strict_mode = DiagnosticMessage{
    .message = "Code contained in a class is evaluated in JavaScript's strict mode which does not allow this use of '{0s}'. For more information, see https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Strict_mode.",
    .category = "Error",
    .code = "1210",
};
pub const a_class_declaration_without_the_default_modifier_must_have_a_name = DiagnosticMessage{
    .message = "A class declaration without the 'default' modifier must have a name.",
    .category = "Error",
    .code = "1211",
};
pub const identifier_expected_ARG_is_a_reserved_word_in_strict_mode = DiagnosticMessage{
    .message = "Identifier expected. '{0s}' is a reserved word in strict mode.",
    .category = "Error",
    .code = "1212",
};
pub const identifier_expected_ARG_is_a_reserved_word_in_strict_mode_class_definitions_are_automatically_in_strict_mode = DiagnosticMessage{
    .message = "Identifier expected. '{0s}' is a reserved word in strict mode. Class definitions are automatically in strict mode.",
    .category = "Error",
    .code = "1213",
};
pub const identifier_expected_ARG_is_a_reserved_word_in_strict_mode_modules_are_automatically_in_strict_mode = DiagnosticMessage{
    .message = "Identifier expected. '{0s}' is a reserved word in strict mode. Modules are automatically in strict mode.",
    .category = "Error",
    .code = "1214",
};
pub const invalid_use_of_ARG_modules_are_automatically_in_strict_mode = DiagnosticMessage{
    .message = "Invalid use of '{0s}'. Modules are automatically in strict mode.",
    .category = "Error",
    .code = "1215",
};
pub const identifier_expected_esmodule_is_reserved_as_an_exported_marker_when_transforming_ecmascript_modules = DiagnosticMessage{
    .message = "Identifier expected. '__esModule' is reserved as an exported marker when transforming ECMAScript modules.",
    .category = "Error",
    .code = "1216",
};
pub const export_assignment_is_not_supported_when_module_flag_is_system = DiagnosticMessage{
    .message = "Export assignment is not supported when '--module' flag is 'system'.",
    .category = "Error",
    .code = "1218",
};
pub const generators_are_not_allowed_in_an_ambient_context = DiagnosticMessage{
    .message = "Generators are not allowed in an ambient context.",
    .category = "Error",
    .code = "1221",
};
pub const an_overload_signature_cannot_be_declared_as_a_generator = DiagnosticMessage{
    .message = "An overload signature cannot be declared as a generator.",
    .category = "Error",
    .code = "1222",
};
pub const ARG_tag_already_specified = DiagnosticMessage{
    .message = "'{0s}' tag already specified.",
    .category = "Error",
    .code = "1223",
};
pub const signature_ARG_must_be_a_type_predicate = DiagnosticMessage{
    .message = "Signature '{0s}' must be a type predicate.",
    .category = "Error",
    .code = "1224",
};
pub const cannot_find_parameter_ARG = DiagnosticMessage{
    .message = "Cannot find parameter '{0s}'.",
    .category = "Error",
    .code = "1225",
};
pub const type_predicate_ARG_is_not_assignable_to_ARG = DiagnosticMessage{
    .message = "Type predicate '{0s}' is not assignable to '{1s}'.",
    .category = "Error",
    .code = "1226",
};
pub const parameter_ARG_is_not_in_the_same_position_as_parameter_ARG = DiagnosticMessage{
    .message = "Parameter '{0s}' is not in the same position as parameter '{1s}'.",
    .category = "Error",
    .code = "1227",
};
pub const a_type_predicate_is_only_allowed_in_return_type_position_for_functions_and_methods = DiagnosticMessage{
    .message = "A type predicate is only allowed in return type position for functions and methods.",
    .category = "Error",
    .code = "1228",
};
pub const a_type_predicate_cannot_reference_a_rest_parameter = DiagnosticMessage{
    .message = "A type predicate cannot reference a rest parameter.",
    .category = "Error",
    .code = "1229",
};
pub const a_type_predicate_cannot_reference_element_ARG_in_a_binding_pattern = DiagnosticMessage{
    .message = "A type predicate cannot reference element '{0s}' in a binding pattern.",
    .category = "Error",
    .code = "1230",
};
pub const an_export_assignment_must_be_at_the_top_level_of_a_file_or_module_declaration = DiagnosticMessage{
    .message = "An export assignment must be at the top level of a file or module declaration.",
    .category = "Error",
    .code = "1231",
};
pub const an_import_declaration_can_only_be_used_at_the_top_level_of_a_namespace_or_module = DiagnosticMessage{
    .message = "An import declaration can only be used at the top level of a namespace or module.",
    .category = "Error",
    .code = "1232",
};
pub const an_export_declaration_can_only_be_used_at_the_top_level_of_a_namespace_or_module = DiagnosticMessage{
    .message = "An export declaration can only be used at the top level of a namespace or module.",
    .category = "Error",
    .code = "1233",
};
pub const an_ambient_module_declaration_is_only_allowed_at_the_top_level_in_a_file = DiagnosticMessage{
    .message = "An ambient module declaration is only allowed at the top level in a file.",
    .category = "Error",
    .code = "1234",
};
pub const a_namespace_declaration_is_only_allowed_at_the_top_level_of_a_namespace_or_module = DiagnosticMessage{
    .message = "A namespace declaration is only allowed at the top level of a namespace or module.",
    .category = "Error",
    .code = "1235",
};
pub const the_return_type_of_a_property_decorator_function_must_be_either_void_or_any = DiagnosticMessage{
    .message = "The return type of a property decorator function must be either 'void' or 'any'.",
    .category = "Error",
    .code = "1236",
};
pub const the_return_type_of_a_parameter_decorator_function_must_be_either_void_or_any = DiagnosticMessage{
    .message = "The return type of a parameter decorator function must be either 'void' or 'any'.",
    .category = "Error",
    .code = "1237",
};
pub const unable_to_resolve_signature_of_class_decorator_when_called_as_an_expression = DiagnosticMessage{
    .message = "Unable to resolve signature of class decorator when called as an expression.",
    .category = "Error",
    .code = "1238",
};
pub const unable_to_resolve_signature_of_parameter_decorator_when_called_as_an_expression = DiagnosticMessage{
    .message = "Unable to resolve signature of parameter decorator when called as an expression.",
    .category = "Error",
    .code = "1239",
};
pub const unable_to_resolve_signature_of_property_decorator_when_called_as_an_expression = DiagnosticMessage{
    .message = "Unable to resolve signature of property decorator when called as an expression.",
    .category = "Error",
    .code = "1240",
};
pub const unable_to_resolve_signature_of_method_decorator_when_called_as_an_expression = DiagnosticMessage{
    .message = "Unable to resolve signature of method decorator when called as an expression.",
    .category = "Error",
    .code = "1241",
};
pub const abstract_modifier_can_only_appear_on_a_class_method_or_property_declaration = DiagnosticMessage{
    .message = "'abstract' modifier can only appear on a class, method, or property declaration.",
    .category = "Error",
    .code = "1242",
};
pub const ARG_modifier_cannot_be_used_with_ARG_modifier = DiagnosticMessage{
    .message = "'{0s}' modifier cannot be used with '{1s}' modifier.",
    .category = "Error",
    .code = "1243",
};
pub const abstract_methods_can_only_appear_within_an_abstract_class = DiagnosticMessage{
    .message = "Abstract methods can only appear within an abstract class.",
    .category = "Error",
    .code = "1244",
};
pub const method_ARG_cannot_have_an_implementation_because_it_is_marked_abstract = DiagnosticMessage{
    .message = "Method '{0s}' cannot have an implementation because it is marked abstract.",
    .category = "Error",
    .code = "1245",
};
pub const an_interface_property_cannot_have_an_initializer = DiagnosticMessage{
    .message = "An interface property cannot have an initializer.",
    .category = "Error",
    .code = "1246",
};
pub const a_type_literal_property_cannot_have_an_initializer = DiagnosticMessage{
    .message = "A type literal property cannot have an initializer.",
    .category = "Error",
    .code = "1247",
};
pub const a_class_member_cannot_have_the_ARG_keyword = DiagnosticMessage{
    .message = "A class member cannot have the '{0s}' keyword.",
    .category = "Error",
    .code = "1248",
};
pub const a_decorator_can_only_decorate_a_method_implementation_not_an_overload = DiagnosticMessage{
    .message = "A decorator can only decorate a method implementation, not an overload.",
    .category = "Error",
    .code = "1249",
};
pub const function_declarations_are_not_allowed_inside_blocks_in_strict_mode_when_targeting_es5 = DiagnosticMessage{
    .message = "Function declarations are not allowed inside blocks in strict mode when targeting 'ES5'.",
    .category = "Error",
    .code = "1250",
};
pub const function_declarations_are_not_allowed_inside_blocks_in_strict_mode_when_targeting_es5_class_definitions_are_automatically_in_strict_mode = DiagnosticMessage{
    .message = "Function declarations are not allowed inside blocks in strict mode when targeting 'ES5'. Class definitions are automatically in strict mode.",
    .category = "Error",
    .code = "1251",
};
pub const function_declarations_are_not_allowed_inside_blocks_in_strict_mode_when_targeting_es5_modules_are_automatically_in_strict_mode = DiagnosticMessage{
    .message = "Function declarations are not allowed inside blocks in strict mode when targeting 'ES5'. Modules are automatically in strict mode.",
    .category = "Error",
    .code = "1252",
};
pub const abstract_properties_can_only_appear_within_an_abstract_class = DiagnosticMessage{
    .message = "Abstract properties can only appear within an abstract class.",
    .category = "Error",
    .code = "1253",
};
pub const a_const_initializer_in_an_ambient_context_must_be_a_string_or_numeric_literal_or_literal_enum_reference = DiagnosticMessage{
    .message = "A 'const' initializer in an ambient context must be a string or numeric literal or literal enum reference.",
    .category = "Error",
    .code = "1254",
};
pub const a_definite_assignment_assertion_is_not_permitted_in_this_context = DiagnosticMessage{
    .message = "A definite assignment assertion '!' is not permitted in this context.",
    .category = "Error",
    .code = "1255",
};
pub const a_required_element_cannot_follow_an_optional_element = DiagnosticMessage{
    .message = "A required element cannot follow an optional element.",
    .category = "Error",
    .code = "1257",
};
pub const a_default_export_must_be_at_the_top_level_of_a_file_or_module_declaration = DiagnosticMessage{
    .message = "A default export must be at the top level of a file or module declaration.",
    .category = "Error",
    .code = "1258",
};
pub const module_ARG_can_only_be_default_imported_using_the_ARG_flag = DiagnosticMessage{
    .message = "Module '{0s}' can only be default-imported using the '{1s}' flag",
    .category = "Error",
    .code = "1259",
};
pub const keywords_cannot_contain_escape_characters = DiagnosticMessage{
    .message = "Keywords cannot contain escape characters.",
    .category = "Error",
    .code = "1260",
};
pub const already_included_file_name_ARG_differs_from_file_name_ARG_only_in_casing = DiagnosticMessage{
    .message = "Already included file name '{0s}' differs from file name '{1s}' only in casing.",
    .category = "Error",
    .code = "1261",
};
pub const identifier_expected_ARG_is_a_reserved_word_at_the_top_level_of_a_module = DiagnosticMessage{
    .message = "Identifier expected. '{0s}' is a reserved word at the top-level of a module.",
    .category = "Error",
    .code = "1262",
};
pub const declarations_with_initializers_cannot_also_have_definite_assignment_assertions = DiagnosticMessage{
    .message = "Declarations with initializers cannot also have definite assignment assertions.",
    .category = "Error",
    .code = "1263",
};
pub const declarations_with_definite_assignment_assertions_must_also_have_type_annotations = DiagnosticMessage{
    .message = "Declarations with definite assignment assertions must also have type annotations.",
    .category = "Error",
    .code = "1264",
};
pub const a_rest_element_cannot_follow_another_rest_element = DiagnosticMessage{
    .message = "A rest element cannot follow another rest element.",
    .category = "Error",
    .code = "1265",
};
pub const an_optional_element_cannot_follow_a_rest_element = DiagnosticMessage{
    .message = "An optional element cannot follow a rest element.",
    .category = "Error",
    .code = "1266",
};
pub const property_ARG_cannot_have_an_initializer_because_it_is_marked_abstract = DiagnosticMessage{
    .message = "Property '{0s}' cannot have an initializer because it is marked abstract.",
    .category = "Error",
    .code = "1267",
};
pub const an_index_signature_parameter_type_must_be_string_number_symbol_or_a_template_literal_type = DiagnosticMessage{
    .message = "An index signature parameter type must be 'string', 'number', 'symbol', or a template literal type.",
    .category = "Error",
    .code = "1268",
};
pub const cannot_use_export_import_on_a_type_or_type_only_namespace_when_ARG_is_enabled = DiagnosticMessage{
    .message = "Cannot use 'export import' on a type or type-only namespace when '{0s}' is enabled.",
    .category = "Error",
    .code = "1269",
};
pub const decorator_function_return_type_ARG_is_not_assignable_to_type_ARG = DiagnosticMessage{
    .message = "Decorator function return type '{0s}' is not assignable to type '{1s}'.",
    .category = "Error",
    .code = "1270",
};
pub const decorator_function_return_type_is_ARG_but_is_expected_to_be_void_or_any = DiagnosticMessage{
    .message = "Decorator function return type is '{0s}' but is expected to be 'void' or 'any'.",
    .category = "Error",
    .code = "1271",
};
pub const a_type_referenced_in_a_decorated_signature_must_be_imported_with_import_type_or_a_namespace_import_when_isolatedmodules_and_emitdecoratormetadata_are_enabled = DiagnosticMessage{
    .message = "A type referenced in a decorated signature must be imported with 'import type' or a namespace import when 'isolatedModules' and 'emitDecoratorMetadata' are enabled.",
    .category = "Error",
    .code = "1272",
};
pub const ARG_modifier_cannot_appear_on_a_type_parameter = DiagnosticMessage{
    .message = "'{0s}' modifier cannot appear on a type parameter",
    .category = "Error",
    .code = "1273",
};
pub const ARG_modifier_can_only_appear_on_a_type_parameter_of_a_class_interface_or_type_alias = DiagnosticMessage{
    .message = "'{0s}' modifier can only appear on a type parameter of a class, interface or type alias",
    .category = "Error",
    .code = "1274",
};
pub const accessor_modifier_can_only_appear_on_a_property_declaration = DiagnosticMessage{
    .message = "'accessor' modifier can only appear on a property declaration.",
    .category = "Error",
    .code = "1275",
};
pub const an_accessor_property_cannot_be_declared_optional = DiagnosticMessage{
    .message = "An 'accessor' property cannot be declared optional.",
    .category = "Error",
    .code = "1276",
};
pub const ARG_modifier_can_only_appear_on_a_type_parameter_of_a_function_method_or_class = DiagnosticMessage{
    .message = "'{0s}' modifier can only appear on a type parameter of a function, method or class",
    .category = "Error",
    .code = "1277",
};
pub const the_runtime_will_invoke_the_decorator_with_ARG_arguments_but_the_decorator_expects_ARG = DiagnosticMessage{
    .message = "The runtime will invoke the decorator with {1s} arguments, but the decorator expects {0s}.",
    .category = "Error",
    .code = "1278",
};
pub const the_runtime_will_invoke_the_decorator_with_ARG_arguments_but_the_decorator_expects_at_least_ARG = DiagnosticMessage{
    .message = "The runtime will invoke the decorator with {1s} arguments, but the decorator expects at least {0s}.",
    .category = "Error",
    .code = "1279",
};
pub const namespaces_are_not_allowed_in_global_script_files_when_ARG_is_enabled_if_this_file_is_not_intended_to_be_a_global_script_set_moduledetection_to_force_or_add_an_empty_export_ARG_statement = DiagnosticMessage{
    .message = "Namespaces are not allowed in global script files when '{0s}' is enabled. If this file is not intended to be a global script, set 'moduleDetection' to 'force' or add an empty 'export {{}' statement.",
    .category = "Error",
    .code = "1280",
};
pub const cannot_access_ARG_from_another_file_without_qualification_when_ARG_is_enabled_use_ARG_instead = DiagnosticMessage{
    .message = "Cannot access '{0s}' from another file without qualification when '{1s}' is enabled. Use '{2s}' instead.",
    .category = "Error",
    .code = "1281",
};
pub const an_export_declaration_must_reference_a_value_when_verbatimmodulesyntax_is_enabled_but_ARG_only_refers_to_a_type = DiagnosticMessage{
    .message = "An 'export =' declaration must reference a value when 'verbatimModuleSyntax' is enabled, but '{0s}' only refers to a type.",
    .category = "Error",
    .code = "1282",
};
pub const an_export_declaration_must_reference_a_real_value_when_verbatimmodulesyntax_is_enabled_but_ARG_resolves_to_a_type_only_declaration = DiagnosticMessage{
    .message = "An 'export =' declaration must reference a real value when 'verbatimModuleSyntax' is enabled, but '{0s}' resolves to a type-only declaration.",
    .category = "Error",
    .code = "1283",
};
pub const an_export_default_must_reference_a_value_when_verbatimmodulesyntax_is_enabled_but_ARG_only_refers_to_a_type = DiagnosticMessage{
    .message = "An 'export default' must reference a value when 'verbatimModuleSyntax' is enabled, but '{0s}' only refers to a type.",
    .category = "Error",
    .code = "1284",
};
pub const an_export_default_must_reference_a_real_value_when_verbatimmodulesyntax_is_enabled_but_ARG_resolves_to_a_type_only_declaration = DiagnosticMessage{
    .message = "An 'export default' must reference a real value when 'verbatimModuleSyntax' is enabled, but '{0s}' resolves to a type-only declaration.",
    .category = "Error",
    .code = "1285",
};
pub const esm_syntax_is_not_allowed_in_a_commonjs_module_when_verbatimmodulesyntax_is_enabled = DiagnosticMessage{
    .message = "ESM syntax is not allowed in a CommonJS module when 'verbatimModuleSyntax' is enabled.",
    .category = "Error",
    .code = "1286",
};
pub const a_top_level_export_modifier_cannot_be_used_on_value_declarations_in_a_commonjs_module_when_verbatimmodulesyntax_is_enabled = DiagnosticMessage{
    .message = "A top-level 'export' modifier cannot be used on value declarations in a CommonJS module when 'verbatimModuleSyntax' is enabled.",
    .category = "Error",
    .code = "1287",
};
pub const an_import_alias_cannot_resolve_to_a_type_or_type_only_declaration_when_verbatimmodulesyntax_is_enabled = DiagnosticMessage{
    .message = "An import alias cannot resolve to a type or type-only declaration when 'verbatimModuleSyntax' is enabled.",
    .category = "Error",
    .code = "1288",
};
pub const ARG_resolves_to_a_type_only_declaration_and_must_be_marked_type_only_in_this_file_before_re_exporting_when_ARG_is_enabled_consider_using_import_type_where_ARG_is_imported = DiagnosticMessage{
    .message = "'{0s}' resolves to a type-only declaration and must be marked type-only in this file before re-exporting when '{1s}' is enabled. Consider using 'import type' where '{0s}' is imported.",
    .category = "Error",
    .code = "1289",
};
pub const ARG_resolves_to_a_type_only_declaration_and_must_be_marked_type_only_in_this_file_before_re_exporting_when_ARG_is_enabled_consider_using_export_type_ARG_as_default = DiagnosticMessage{
    .message = "'{0s}' resolves to a type-only declaration and must be marked type-only in this file before re-exporting when '{1s}' is enabled. Consider using 'export type {{ {0s} as default }'.",
    .category = "Error",
    .code = "1290",
};
pub const ARG_resolves_to_a_type_and_must_be_marked_type_only_in_this_file_before_re_exporting_when_ARG_is_enabled_consider_using_import_type_where_ARG_is_imported = DiagnosticMessage{
    .message = "'{0s}' resolves to a type and must be marked type-only in this file before re-exporting when '{1s}' is enabled. Consider using 'import type' where '{0s}' is imported.",
    .category = "Error",
    .code = "1291",
};
pub const ARG_resolves_to_a_type_and_must_be_marked_type_only_in_this_file_before_re_exporting_when_ARG_is_enabled_consider_using_export_type_ARG_as_default = DiagnosticMessage{
    .message = "'{0s}' resolves to a type and must be marked type-only in this file before re-exporting when '{1s}' is enabled. Consider using 'export type {{ {0s} as default }'.",
    .category = "Error",
    .code = "1292",
};
pub const esm_syntax_is_not_allowed_in_a_commonjs_module_when_module_is_set_to_preserve = DiagnosticMessage{
    .message = "ESM syntax is not allowed in a CommonJS module when 'module' is set to 'preserve'.",
    .category = "Error",
    .code = "1293",
};
pub const with_statements_are_not_allowed_in_an_async_function_block = DiagnosticMessage{
    .message = "'with' statements are not allowed in an async function block.",
    .category = "Error",
    .code = "1300",
};
pub const await_expressions_are_only_allowed_within_async_functions_and_at_the_top_levels_of_modules = DiagnosticMessage{
    .message = "'await' expressions are only allowed within async functions and at the top levels of modules.",
    .category = "Error",
    .code = "1308",
};
pub const the_current_file_is_a_commonjs_module_and_cannot_use_await_at_the_top_level = DiagnosticMessage{
    .message = "The current file is a CommonJS module and cannot use 'await' at the top level.",
    .category = "Error",
    .code = "1309",
};
pub const did_you_mean_to_use_a_an_can_only_follow_a_property_name_when_the_containing_object_literal_is_part_of_a_destructuring_pattern = DiagnosticMessage{
    .message = "Did you mean to use a ':'? An '=' can only follow a property name when the containing object literal is part of a destructuring pattern.",
    .category = "Error",
    .code = "1312",
};
pub const the_body_of_an_if_statement_cannot_be_the_empty_statement = DiagnosticMessage{
    .message = "The body of an 'if' statement cannot be the empty statement.",
    .category = "Error",
    .code = "1313",
};
pub const global_module_exports_may_only_appear_in_module_files = DiagnosticMessage{
    .message = "Global module exports may only appear in module files.",
    .category = "Error",
    .code = "1314",
};
pub const global_module_exports_may_only_appear_in_declaration_files = DiagnosticMessage{
    .message = "Global module exports may only appear in declaration files.",
    .category = "Error",
    .code = "1315",
};
pub const global_module_exports_may_only_appear_at_top_level = DiagnosticMessage{
    .message = "Global module exports may only appear at top level.",
    .category = "Error",
    .code = "1316",
};
pub const a_parameter_property_cannot_be_declared_using_a_rest_parameter = DiagnosticMessage{
    .message = "A parameter property cannot be declared using a rest parameter.",
    .category = "Error",
    .code = "1317",
};
pub const an_abstract_accessor_cannot_have_an_implementation = DiagnosticMessage{
    .message = "An abstract accessor cannot have an implementation.",
    .category = "Error",
    .code = "1318",
};
pub const a_default_export_can_only_be_used_in_an_ecmascript_style_module = DiagnosticMessage{
    .message = "A default export can only be used in an ECMAScript-style module.",
    .category = "Error",
    .code = "1319",
};
pub const type_of_await_operand_must_either_be_a_valid_promise_or_must_not_contain_a_callable_then_member = DiagnosticMessage{
    .message = "Type of 'await' operand must either be a valid promise or must not contain a callable 'then' member.",
    .category = "Error",
    .code = "1320",
};
pub const type_of_yield_operand_in_an_async_generator_must_either_be_a_valid_promise_or_must_not_contain_a_callable_then_member = DiagnosticMessage{
    .message = "Type of 'yield' operand in an async generator must either be a valid promise or must not contain a callable 'then' member.",
    .category = "Error",
    .code = "1321",
};
pub const type_of_iterated_elements_of_a_yield_operand_must_either_be_a_valid_promise_or_must_not_contain_a_callable_then_member = DiagnosticMessage{
    .message = "Type of iterated elements of a 'yield*' operand must either be a valid promise or must not contain a callable 'then' member.",
    .category = "Error",
    .code = "1322",
};
pub const dynamic_imports_are_only_supported_when_the_module_flag_is_set_to_es2020_es2022_esnext_commonjs_amd_system_umd_node16_or_nodenext = DiagnosticMessage{
    .message = "Dynamic imports are only supported when the '--module' flag is set to 'es2020', 'es2022', 'esnext', 'commonjs', 'amd', 'system', 'umd', 'node16', or 'nodenext'.",
    .category = "Error",
    .code = "1323",
};
pub const dynamic_imports_only_support_a_second_argument_when_the_module_option_is_set_to_esnext_node16_or_nodenext = DiagnosticMessage{
    .message = "Dynamic imports only support a second argument when the '--module' option is set to 'esnext', 'node16', or 'nodenext'.",
    .category = "Error",
    .code = "1324",
};
pub const argument_of_dynamic_import_cannot_be_spread_element = DiagnosticMessage{
    .message = "Argument of dynamic import cannot be spread element.",
    .category = "Error",
    .code = "1325",
};
pub const this_use_of_import_is_invalid_import_calls_can_be_written_but_they_must_have_parentheses_and_cannot_have_type_arguments = DiagnosticMessage{
    .message = "This use of 'import' is invalid. 'import()' calls can be written, but they must have parentheses and cannot have type arguments.",
    .category = "Error",
    .code = "1326",
};
pub const string_literal_with_double_quotes_expected = DiagnosticMessage{
    .message = "String literal with double quotes expected.",
    .category = "Error",
    .code = "1327",
};
pub const property_value_can_only_be_string_literal_numeric_literal_true_false_null_object_literal_or_array_literal = DiagnosticMessage{
    .message = "Property value can only be string literal, numeric literal, 'true', 'false', 'null', object literal or array literal.",
    .category = "Error",
    .code = "1328",
};
pub const ARG_accepts_too_few_arguments_to_be_used_as_a_decorator_here_did_you_mean_to_call_it_first_and_write_ARG = DiagnosticMessage{
    .message = "'{0s}' accepts too few arguments to be used as a decorator here. Did you mean to call it first and write '@{0s}()'?",
    .category = "Error",
    .code = "1329",
};
pub const a_property_of_an_interface_or_type_literal_whose_type_is_a_unique_symbol_type_must_be_readonly = DiagnosticMessage{
    .message = "A property of an interface or type literal whose type is a 'unique symbol' type must be 'readonly'.",
    .category = "Error",
    .code = "1330",
};
pub const a_property_of_a_class_whose_type_is_a_unique_symbol_type_must_be_both_static_and_readonly = DiagnosticMessage{
    .message = "A property of a class whose type is a 'unique symbol' type must be both 'static' and 'readonly'.",
    .category = "Error",
    .code = "1331",
};
pub const a_variable_whose_type_is_a_unique_symbol_type_must_be_const = DiagnosticMessage{
    .message = "A variable whose type is a 'unique symbol' type must be 'const'.",
    .category = "Error",
    .code = "1332",
};
pub const unique_symbol_types_may_not_be_used_on_a_variable_declaration_with_a_binding_name = DiagnosticMessage{
    .message = "'unique symbol' types may not be used on a variable declaration with a binding name.",
    .category = "Error",
    .code = "1333",
};
pub const unique_symbol_types_are_only_allowed_on_variables_in_a_variable_statement = DiagnosticMessage{
    .message = "'unique symbol' types are only allowed on variables in a variable statement.",
    .category = "Error",
    .code = "1334",
};
pub const unique_symbol_types_are_not_allowed_here = DiagnosticMessage{
    .message = "'unique symbol' types are not allowed here.",
    .category = "Error",
    .code = "1335",
};
pub const an_index_signature_parameter_type_cannot_be_a_literal_type_or_generic_type_consider_using_a_mapped_object_type_instead = DiagnosticMessage{
    .message = "An index signature parameter type cannot be a literal type or generic type. Consider using a mapped object type instead.",
    .category = "Error",
    .code = "1337",
};
pub const infer_declarations_are_only_permitted_in_the_extends_clause_of_a_conditional_type = DiagnosticMessage{
    .message = "'infer' declarations are only permitted in the 'extends' clause of a conditional type.",
    .category = "Error",
    .code = "1338",
};
pub const module_ARG_does_not_refer_to_a_value_but_is_used_as_a_value_here = DiagnosticMessage{
    .message = "Module '{0s}' does not refer to a value, but is used as a value here.",
    .category = "Error",
    .code = "1339",
};
pub const module_ARG_does_not_refer_to_a_type_but_is_used_as_a_type_here_did_you_mean_typeof_import_ARG = DiagnosticMessage{
    .message = "Module '{0s}' does not refer to a type, but is used as a type here. Did you mean 'typeof import('{0s}')'?",
    .category = "Error",
    .code = "1340",
};
pub const class_constructor_may_not_be_an_accessor = DiagnosticMessage{
    .message = "Class constructor may not be an accessor.",
    .category = "Error",
    .code = "1341",
};
pub const the_import_meta_meta_property_is_only_allowed_when_the_module_option_is_es2020_es2022_esnext_system_node16_or_nodenext = DiagnosticMessage{
    .message = "The 'import.meta' meta-property is only allowed when the '--module' option is 'es2020', 'es2022', 'esnext', 'system', 'node16', or 'nodenext'.",
    .category = "Error",
    .code = "1343",
};
pub const a_label_is_not_allowed_here = DiagnosticMessage{
    .message = "'A label is not allowed here.",
    .category = "Error",
    .code = "1344",
};
pub const an_expression_of_type_void_cannot_be_tested_for_truthiness = DiagnosticMessage{
    .message = "An expression of type 'void' cannot be tested for truthiness.",
    .category = "Error",
    .code = "1345",
};
pub const this_parameter_is_not_allowed_with_use_strict_directive = DiagnosticMessage{
    .message = "This parameter is not allowed with 'use strict' directive.",
    .category = "Error",
    .code = "1346",
};
pub const use_strict_directive_cannot_be_used_with_non_simple_parameter_list = DiagnosticMessage{
    .message = "'use strict' directive cannot be used with non-simple parameter list.",
    .category = "Error",
    .code = "1347",
};
pub const non_simple_parameter_declared_here = DiagnosticMessage{
    .message = "Non-simple parameter declared here.",
    .category = "Error",
    .code = "1348",
};
pub const use_strict_directive_used_here = DiagnosticMessage{
    .message = "'use strict' directive used here.",
    .category = "Error",
    .code = "1349",
};
pub const print_the_final_configuration_instead_of_building = DiagnosticMessage{
    .message = "Print the final configuration instead of building.",
    .category = "Message",
    .code = "1350",
};
pub const an_identifier_or_keyword_cannot_immediately_follow_a_numeric_literal = DiagnosticMessage{
    .message = "An identifier or keyword cannot immediately follow a numeric literal.",
    .category = "Error",
    .code = "1351",
};
pub const a_bigint_literal_cannot_use_exponential_notation = DiagnosticMessage{
    .message = "A bigint literal cannot use exponential notation.",
    .category = "Error",
    .code = "1352",
};
pub const a_bigint_literal_must_be_an_integer = DiagnosticMessage{
    .message = "A bigint literal must be an integer.",
    .category = "Error",
    .code = "1353",
};
pub const readonly_type_modifier_is_only_permitted_on_array_and_tuple_literal_types = DiagnosticMessage{
    .message = "'readonly' type modifier is only permitted on array and tuple literal types.",
    .category = "Error",
    .code = "1354",
};
pub const a_const_assertions_can_only_be_applied_to_references_to_enum_members_or_string_number_boolean_array_or_object_literals = DiagnosticMessage{
    .message = "A 'const' assertions can only be applied to references to enum members, or string, number, boolean, array, or object literals.",
    .category = "Error",
    .code = "1355",
};
pub const did_you_mean_to_mark_this_function_as_async = DiagnosticMessage{
    .message = "Did you mean to mark this function as 'async'?",
    .category = "Error",
    .code = "1356",
};
pub const an_enum_member_name_must_be_followed_by_a_or = DiagnosticMessage{
    .message = "An enum member name must be followed by a ',', '=', or '}'.",
    .category = "Error",
    .code = "1357",
};
pub const tagged_template_expressions_are_not_permitted_in_an_optional_chain = DiagnosticMessage{
    .message = "Tagged template expressions are not permitted in an optional chain.",
    .category = "Error",
    .code = "1358",
};
pub const identifier_expected_ARG_is_a_reserved_word_that_cannot_be_used_here = DiagnosticMessage{
    .message = "Identifier expected. '{0s}' is a reserved word that cannot be used here.",
    .category = "Error",
    .code = "1359",
};
pub const type_ARG_does_not_satisfy_the_expected_type_ARG = DiagnosticMessage{
    .message = "Type '{0s}' does not satisfy the expected type '{1s}'.",
    .category = "Error",
    .code = "1360",
};
pub const ARG_cannot_be_used_as_a_value_because_it_was_imported_using_import_type = DiagnosticMessage{
    .message = "'{0s}' cannot be used as a value because it was imported using 'import type'.",
    .category = "Error",
    .code = "1361",
};
pub const ARG_cannot_be_used_as_a_value_because_it_was_exported_using_export_type = DiagnosticMessage{
    .message = "'{0s}' cannot be used as a value because it was exported using 'export type'.",
    .category = "Error",
    .code = "1362",
};
pub const a_type_only_import_can_specify_a_default_import_or_named_bindings_but_not_both = DiagnosticMessage{
    .message = "A type-only import can specify a default import or named bindings, but not both.",
    .category = "Error",
    .code = "1363",
};
pub const convert_to_type_only_export = DiagnosticMessage{
    .message = "Convert to type-only export",
    .category = "Message",
    .code = "1364",
};
pub const convert_all_re_exported_types_to_type_only_exports = DiagnosticMessage{
    .message = "Convert all re-exported types to type-only exports",
    .category = "Message",
    .code = "1365",
};
pub const split_into_two_separate_import_declarations = DiagnosticMessage{
    .message = "Split into two separate import declarations",
    .category = "Message",
    .code = "1366",
};
pub const split_all_invalid_type_only_imports = DiagnosticMessage{
    .message = "Split all invalid type-only imports",
    .category = "Message",
    .code = "1367",
};
pub const class_constructor_may_not_be_a_generator = DiagnosticMessage{
    .message = "Class constructor may not be a generator.",
    .category = "Error",
    .code = "1368",
};
pub const did_you_mean_ARG = DiagnosticMessage{
    .message = "Did you mean '{0s}'?",
    .category = "Message",
    .code = "1369",
};
pub const await_expressions_are_only_allowed_at_the_top_level_of_a_file_when_that_file_is_a_module_but_this_file_has_no_imports_or_exports_consider_adding_an_empty_export_ARG_to_make_this_file_a_module = DiagnosticMessage{
    .message = "'await' expressions are only allowed at the top level of a file when that file is a module, but this file has no imports or exports. Consider adding an empty 'export {{}' to make this file a module.",
    .category = "Error",
    .code = "1375",
};
pub const ARG_was_imported_here = DiagnosticMessage{
    .message = "'{0s}' was imported here.",
    .category = "Message",
    .code = "1376",
};
pub const ARG_was_exported_here = DiagnosticMessage{
    .message = "'{0s}' was exported here.",
    .category = "Message",
    .code = "1377",
};
pub const top_level_await_expressions_are_only_allowed_when_the_module_option_is_set_to_es2022_esnext_system_node16_nodenext_or_preserve_and_the_target_option_is_set_to_es2017_or_higher = DiagnosticMessage{
    .message = "Top-level 'await' expressions are only allowed when the 'module' option is set to 'es2022', 'esnext', 'system', 'node16', 'nodenext', or 'preserve', and the 'target' option is set to 'es2017' or higher.",
    .category = "Error",
    .code = "1378",
};
pub const an_import_alias_cannot_reference_a_declaration_that_was_exported_using_export_type = DiagnosticMessage{
    .message = "An import alias cannot reference a declaration that was exported using 'export type'.",
    .category = "Error",
    .code = "1379",
};
pub const an_import_alias_cannot_reference_a_declaration_that_was_imported_using_import_type = DiagnosticMessage{
    .message = "An import alias cannot reference a declaration that was imported using 'import type'.",
    .category = "Error",
    .code = "1380",
};
pub const unexpected_token_did_you_mean_ARG_or_rbrace = DiagnosticMessage{
    .message = "Unexpected token. Did you mean `{'s}'}` or `&rbrace;`?",
    .category = "Error",
    .code = "1381",
};
pub const unexpected_token_did_you_mean_ARG_or_gt = DiagnosticMessage{
    .message = "Unexpected token. Did you mean `{{'>'}` or `&gt;`?",
    .category = "Error",
    .code = "1382",
};
pub const function_type_notation_must_be_parenthesized_when_used_in_a_union_type = DiagnosticMessage{
    .message = "Function type notation must be parenthesized when used in a union type.",
    .category = "Error",
    .code = "1385",
};
pub const constructor_type_notation_must_be_parenthesized_when_used_in_a_union_type = DiagnosticMessage{
    .message = "Constructor type notation must be parenthesized when used in a union type.",
    .category = "Error",
    .code = "1386",
};
pub const function_type_notation_must_be_parenthesized_when_used_in_an_intersection_type = DiagnosticMessage{
    .message = "Function type notation must be parenthesized when used in an intersection type.",
    .category = "Error",
    .code = "1387",
};
pub const constructor_type_notation_must_be_parenthesized_when_used_in_an_intersection_type = DiagnosticMessage{
    .message = "Constructor type notation must be parenthesized when used in an intersection type.",
    .category = "Error",
    .code = "1388",
};
pub const ARG_is_not_allowed_as_a_variable_declaration_name = DiagnosticMessage{
    .message = "'{0s}' is not allowed as a variable declaration name.",
    .category = "Error",
    .code = "1389",
};
pub const ARG_is_not_allowed_as_a_parameter_name = DiagnosticMessage{
    .message = "'{0s}' is not allowed as a parameter name.",
    .category = "Error",
    .code = "1390",
};
pub const an_import_alias_cannot_use_import_type = DiagnosticMessage{
    .message = "An import alias cannot use 'import type'",
    .category = "Error",
    .code = "1392",
};
pub const imported_via_ARG_from_file_ARG = DiagnosticMessage{
    .message = "Imported via {0s} from file '{1s}'",
    .category = "Message",
    .code = "1393",
};
pub const imported_via_ARG_from_file_ARG_with_packageid_ARG = DiagnosticMessage{
    .message = "Imported via {0s} from file '{1s}' with packageId '{2s}'",
    .category = "Message",
    .code = "1394",
};
pub const imported_via_ARG_from_file_ARG_to_import_importhelpers_as_specified_in_compileroptions = DiagnosticMessage{
    .message = "Imported via {0s} from file '{1s}' to import 'importHelpers' as specified in compilerOptions",
    .category = "Message",
    .code = "1395",
};
pub const imported_via_ARG_from_file_ARG_with_packageid_ARG_to_import_importhelpers_as_specified_in_compileroptions = DiagnosticMessage{
    .message = "Imported via {0s} from file '{1s}' with packageId '{2s}' to import 'importHelpers' as specified in compilerOptions",
    .category = "Message",
    .code = "1396",
};
pub const imported_via_ARG_from_file_ARG_to_import_jsx_and_jsxs_factory_functions = DiagnosticMessage{
    .message = "Imported via {0s} from file '{1s}' to import 'jsx' and 'jsxs' factory functions",
    .category = "Message",
    .code = "1397",
};
pub const imported_via_ARG_from_file_ARG_with_packageid_ARG_to_import_jsx_and_jsxs_factory_functions = DiagnosticMessage{
    .message = "Imported via {0s} from file '{1s}' with packageId '{2s}' to import 'jsx' and 'jsxs' factory functions",
    .category = "Message",
    .code = "1398",
};
pub const file_is_included_via_import_here = DiagnosticMessage{
    .message = "File is included via import here.",
    .category = "Message",
    .code = "1399",
};
pub const referenced_via_ARG_from_file_ARG = DiagnosticMessage{
    .message = "Referenced via '{0s}' from file '{1s}'",
    .category = "Message",
    .code = "1400",
};
pub const file_is_included_via_reference_here = DiagnosticMessage{
    .message = "File is included via reference here.",
    .category = "Message",
    .code = "1401",
};
pub const type_library_referenced_via_ARG_from_file_ARG = DiagnosticMessage{
    .message = "Type library referenced via '{0s}' from file '{1s}'",
    .category = "Message",
    .code = "1402",
};
pub const type_library_referenced_via_ARG_from_file_ARG_with_packageid_ARG = DiagnosticMessage{
    .message = "Type library referenced via '{0s}' from file '{1s}' with packageId '{2s}'",
    .category = "Message",
    .code = "1403",
};
pub const file_is_included_via_type_library_reference_here = DiagnosticMessage{
    .message = "File is included via type library reference here.",
    .category = "Message",
    .code = "1404",
};
pub const library_referenced_via_ARG_from_file_ARG = DiagnosticMessage{
    .message = "Library referenced via '{0s}' from file '{1s}'",
    .category = "Message",
    .code = "1405",
};
pub const file_is_included_via_library_reference_here = DiagnosticMessage{
    .message = "File is included via library reference here.",
    .category = "Message",
    .code = "1406",
};
pub const matched_by_include_pattern_ARG_in_ARG = DiagnosticMessage{
    .message = "Matched by include pattern '{0s}' in '{1s}'",
    .category = "Message",
    .code = "1407",
};
pub const file_is_matched_by_include_pattern_specified_here = DiagnosticMessage{
    .message = "File is matched by include pattern specified here.",
    .category = "Message",
    .code = "1408",
};
pub const part_of_files_list_in_tsconfig_json = DiagnosticMessage{
    .message = "Part of 'files' list in tsconfig.json",
    .category = "Message",
    .code = "1409",
};
pub const file_is_matched_by_files_list_specified_here = DiagnosticMessage{
    .message = "File is matched by 'files' list specified here.",
    .category = "Message",
    .code = "1410",
};
pub const output_from_referenced_project_ARG_included_because_ARG_specified = DiagnosticMessage{
    .message = "Output from referenced project '{0s}' included because '{1s}' specified",
    .category = "Message",
    .code = "1411",
};
pub const output_from_referenced_project_ARG_included_because_module_is_specified_as_none = DiagnosticMessage{
    .message = "Output from referenced project '{0s}' included because '--module' is specified as 'none'",
    .category = "Message",
    .code = "1412",
};
pub const file_is_output_from_referenced_project_specified_here = DiagnosticMessage{
    .message = "File is output from referenced project specified here.",
    .category = "Message",
    .code = "1413",
};
pub const source_from_referenced_project_ARG_included_because_ARG_specified = DiagnosticMessage{
    .message = "Source from referenced project '{0s}' included because '{1s}' specified",
    .category = "Message",
    .code = "1414",
};
pub const source_from_referenced_project_ARG_included_because_module_is_specified_as_none = DiagnosticMessage{
    .message = "Source from referenced project '{0s}' included because '--module' is specified as 'none'",
    .category = "Message",
    .code = "1415",
};
pub const file_is_source_from_referenced_project_specified_here = DiagnosticMessage{
    .message = "File is source from referenced project specified here.",
    .category = "Message",
    .code = "1416",
};
pub const entry_point_of_type_library_ARG_specified_in_compileroptions = DiagnosticMessage{
    .message = "Entry point of type library '{0s}' specified in compilerOptions",
    .category = "Message",
    .code = "1417",
};
pub const entry_point_of_type_library_ARG_specified_in_compileroptions_with_packageid_ARG = DiagnosticMessage{
    .message = "Entry point of type library '{0s}' specified in compilerOptions with packageId '{1s}'",
    .category = "Message",
    .code = "1418",
};
pub const file_is_entry_point_of_type_library_specified_here = DiagnosticMessage{
    .message = "File is entry point of type library specified here.",
    .category = "Message",
    .code = "1419",
};
pub const entry_point_for_implicit_type_library_ARG = DiagnosticMessage{
    .message = "Entry point for implicit type library '{0s}'",
    .category = "Message",
    .code = "1420",
};
pub const entry_point_for_implicit_type_library_ARG_with_packageid_ARG = DiagnosticMessage{
    .message = "Entry point for implicit type library '{0s}' with packageId '{1s}'",
    .category = "Message",
    .code = "1421",
};
pub const library_ARG_specified_in_compileroptions = DiagnosticMessage{
    .message = "Library '{0s}' specified in compilerOptions",
    .category = "Message",
    .code = "1422",
};
pub const file_is_library_specified_here = DiagnosticMessage{
    .message = "File is library specified here.",
    .category = "Message",
    .code = "1423",
};
pub const default_library = DiagnosticMessage{
    .message = "Default library",
    .category = "Message",
    .code = "1424",
};
pub const default_library_for_target_ARG = DiagnosticMessage{
    .message = "Default library for target '{0s}'",
    .category = "Message",
    .code = "1425",
};
pub const file_is_default_library_for_target_specified_here = DiagnosticMessage{
    .message = "File is default library for target specified here.",
    .category = "Message",
    .code = "1426",
};
pub const root_file_specified_for_compilation = DiagnosticMessage{
    .message = "Root file specified for compilation",
    .category = "Message",
    .code = "1427",
};
pub const file_is_output_of_project_reference_source_ARG = DiagnosticMessage{
    .message = "File is output of project reference source '{0s}'",
    .category = "Message",
    .code = "1428",
};
pub const file_redirects_to_file_ARG = DiagnosticMessage{
    .message = "File redirects to file '{0s}'",
    .category = "Message",
    .code = "1429",
};
pub const the_file_is_in_the_program_because = DiagnosticMessage{
    .message = "The file is in the program because:",
    .category = "Message",
    .code = "1430",
};
pub const for_await_loops_are_only_allowed_at_the_top_level_of_a_file_when_that_file_is_a_module_but_this_file_has_no_imports_or_exports_consider_adding_an_empty_export_ARG_to_make_this_file_a_module = DiagnosticMessage{
    .message = "'for await' loops are only allowed at the top level of a file when that file is a module, but this file has no imports or exports. Consider adding an empty 'export {{}' to make this file a module.",
    .category = "Error",
    .code = "1431",
};
pub const top_level_for_await_loops_are_only_allowed_when_the_module_option_is_set_to_es2022_esnext_system_node16_nodenext_or_preserve_and_the_target_option_is_set_to_es2017_or_higher = DiagnosticMessage{
    .message = "Top-level 'for await' loops are only allowed when the 'module' option is set to 'es2022', 'esnext', 'system', 'node16', 'nodenext', or 'preserve', and the 'target' option is set to 'es2017' or higher.",
    .category = "Error",
    .code = "1432",
};
pub const neither_decorators_nor_modifiers_may_be_applied_to_this_parameters = DiagnosticMessage{
    .message = "Neither decorators nor modifiers may be applied to 'this' parameters.",
    .category = "Error",
    .code = "1433",
};
pub const unexpected_keyword_or_identifier = DiagnosticMessage{
    .message = "Unexpected keyword or identifier.",
    .category = "Error",
    .code = "1434",
};
pub const unknown_keyword_or_identifier_did_you_mean_ARG = DiagnosticMessage{
    .message = "Unknown keyword or identifier. Did you mean '{0s}'?",
    .category = "Error",
    .code = "1435",
};
pub const decorators_must_precede_the_name_and_all_keywords_of_property_declarations = DiagnosticMessage{
    .message = "Decorators must precede the name and all keywords of property declarations.",
    .category = "Error",
    .code = "1436",
};
pub const namespace_must_be_given_a_name = DiagnosticMessage{
    .message = "Namespace must be given a name.",
    .category = "Error",
    .code = "1437",
};
pub const interface_must_be_given_a_name = DiagnosticMessage{
    .message = "Interface must be given a name.",
    .category = "Error",
    .code = "1438",
};
pub const type_alias_must_be_given_a_name = DiagnosticMessage{
    .message = "Type alias must be given a name.",
    .category = "Error",
    .code = "1439",
};
pub const variable_declaration_not_allowed_at_this_location = DiagnosticMessage{
    .message = "Variable declaration not allowed at this location.",
    .category = "Error",
    .code = "1440",
};
pub const cannot_start_a_function_call_in_a_type_annotation = DiagnosticMessage{
    .message = "Cannot start a function call in a type annotation.",
    .category = "Error",
    .code = "1441",
};
pub const expected_for_property_initializer = DiagnosticMessage{
    .message = "Expected '=' for property initializer.",
    .category = "Error",
    .code = "1442",
};
pub const module_declaration_names_may_only_use_or_quoted_strings = DiagnosticMessage{
    .message = "Module declaration names may only use ' or \" quoted strings.",
    .category = "Error",
    .code = "1443",
};
pub const ARG_resolves_to_a_type_only_declaration_and_must_be_re_exported_using_a_type_only_re_export_when_ARG_is_enabled = DiagnosticMessage{
    .message = "'{0s}' resolves to a type-only declaration and must be re-exported using a type-only re-export when '{1s}' is enabled.",
    .category = "Error",
    .code = "1448",
};
pub const preserve_unused_imported_values_in_the_javascript_output_that_would_otherwise_be_removed = DiagnosticMessage{
    .message = "Preserve unused imported values in the JavaScript output that would otherwise be removed.",
    .category = "Message",
    .code = "1449",
};
pub const dynamic_imports_can_only_accept_a_module_specifier_and_an_optional_set_of_attributes_as_arguments = DiagnosticMessage{
    .message = "Dynamic imports can only accept a module specifier and an optional set of attributes as arguments",
    .category = "Message",
    .code = "1450",
};
pub const private_identifiers_are_only_allowed_in_class_bodies_and_may_only_be_used_as_part_of_a_class_member_declaration_property_access_or_on_the_left_hand_side_of_an_in_expression = DiagnosticMessage{
    .message = "Private identifiers are only allowed in class bodies and may only be used as part of a class member declaration, property access, or on the left-hand-side of an 'in' expression",
    .category = "Error",
    .code = "1451",
};
pub const resolution_mode_should_be_either_require_or_import = DiagnosticMessage{
    .message = "`resolution-mode` should be either `require` or `import`.",
    .category = "Error",
    .code = "1453",
};
pub const resolution_mode_can_only_be_set_for_type_only_imports = DiagnosticMessage{
    .message = "`resolution-mode` can only be set for type-only imports.",
    .category = "Error",
    .code = "1454",
};
pub const resolution_mode_is_the_only_valid_key_for_type_import_assertions = DiagnosticMessage{
    .message = "`resolution-mode` is the only valid key for type import assertions.",
    .category = "Error",
    .code = "1455",
};
pub const type_import_assertions_should_have_exactly_one_key_resolution_mode_with_value_import_or_require = DiagnosticMessage{
    .message = "Type import assertions should have exactly one key - `resolution-mode` - with value `import` or `require`.",
    .category = "Error",
    .code = "1456",
};
pub const matched_by_default_include_pattern = DiagnosticMessage{
    .message = "Matched by default include pattern '**/*'",
    .category = "Message",
    .code = "1457",
};
pub const file_is_ecmascript_module_because_ARG_has_field_type_with_value_module = DiagnosticMessage{
    .message = "File is ECMAScript module because '{0s}' has field \"type\" with value \"module\"",
    .category = "Message",
    .code = "1458",
};
pub const file_is_commonjs_module_because_ARG_has_field_type_whose_value_is_not_module = DiagnosticMessage{
    .message = "File is CommonJS module because '{0s}' has field \"type\" whose value is not \"module\"",
    .category = "Message",
    .code = "1459",
};
pub const file_is_commonjs_module_because_ARG_does_not_have_field_type = DiagnosticMessage{
    .message = "File is CommonJS module because '{0s}' does not have field \"type\"",
    .category = "Message",
    .code = "1460",
};
pub const file_is_commonjs_module_because_package_json_was_not_found = DiagnosticMessage{
    .message = "File is CommonJS module because 'package.json' was not found",
    .category = "Message",
    .code = "1461",
};
pub const resolution_mode_is_the_only_valid_key_for_type_import_attributes = DiagnosticMessage{
    .message = "'resolution-mode' is the only valid key for type import attributes.",
    .category = "Error",
    .code = "1463",
};
pub const type_import_attributes_should_have_exactly_one_key_resolution_mode_with_value_import_or_require = DiagnosticMessage{
    .message = "Type import attributes should have exactly one key - 'resolution-mode' - with value 'import' or 'require'.",
    .category = "Error",
    .code = "1464",
};
pub const the_import_meta_meta_property_is_not_allowed_in_files_which_will_build_into_commonjs_output = DiagnosticMessage{
    .message = "The 'import.meta' meta-property is not allowed in files which will build into CommonJS output.",
    .category = "Error",
    .code = "1470",
};
pub const module_ARG_cannot_be_imported_using_this_construct_the_specifier_only_resolves_to_an_es_module_which_cannot_be_imported_with_require_use_an_ecmascript_import_instead = DiagnosticMessage{
    .message = "Module '{0s}' cannot be imported using this construct. The specifier only resolves to an ES module, which cannot be imported with 'require'. Use an ECMAScript import instead.",
    .category = "Error",
    .code = "1471",
};
pub const catch_or_finally_expected = DiagnosticMessage{
    .message = "'catch' or 'finally' expected.",
    .category = "Error",
    .code = "1472",
};
pub const an_import_declaration_can_only_be_used_at_the_top_level_of_a_module = DiagnosticMessage{
    .message = "An import declaration can only be used at the top level of a module.",
    .category = "Error",
    .code = "1473",
};
pub const an_export_declaration_can_only_be_used_at_the_top_level_of_a_module = DiagnosticMessage{
    .message = "An export declaration can only be used at the top level of a module.",
    .category = "Error",
    .code = "1474",
};
pub const control_what_method_is_used_to_detect_module_format_js_files = DiagnosticMessage{
    .message = "Control what method is used to detect module-format JS files.",
    .category = "Message",
    .code = "1475",
};
pub const auto_treat_files_with_imports_exports_import_meta_jsx_with_jsx_react_jsx_or_esm_format_with_module_node16_as_modules = DiagnosticMessage{
    .message = "\"auto\": Treat files with imports, exports, import.meta, jsx (with jsx: react-jsx), or esm format (with module: node16+) as modules.",
    .category = "Message",
    .code = "1476",
};
pub const an_instantiation_expression_cannot_be_followed_by_a_property_access = DiagnosticMessage{
    .message = "An instantiation expression cannot be followed by a property access.",
    .category = "Error",
    .code = "1477",
};
pub const identifier_or_string_literal_expected = DiagnosticMessage{
    .message = "Identifier or string literal expected.",
    .category = "Error",
    .code = "1478",
};
pub const the_current_file_is_a_commonjs_module_whose_imports_will_produce_require_calls_however_the_referenced_file_is_an_ecmascript_module_and_cannot_be_imported_with_require_consider_writing_a_dynamic_import_ARG_call_instead = DiagnosticMessage{
    .message = "The current file is a CommonJS module whose imports will produce 'require' calls; however, the referenced file is an ECMAScript module and cannot be imported with 'require'. Consider writing a dynamic 'import(\"{0s}\")' call instead.",
    .category = "Error",
    .code = "1479",
};
pub const to_convert_this_file_to_an_ecmascript_module_change_its_file_extension_to_ARG_or_create_a_local_package_json_file_with_ARG = DiagnosticMessage{
    .message = "To convert this file to an ECMAScript module, change its file extension to '{0s}' or create a local package.json file with `{{ \"type\": \"module\" }`.",
    .category = "Message",
    .code = "1480",
};
pub const to_convert_this_file_to_an_ecmascript_module_change_its_file_extension_to_ARG_or_add_the_field_type_module_to_ARG = DiagnosticMessage{
    .message = "To convert this file to an ECMAScript module, change its file extension to '{0s}', or add the field `\"type\": \"module\"` to '{1s}'.",
    .category = "Message",
    .code = "1481",
};
pub const to_convert_this_file_to_an_ecmascript_module_add_the_field_type_module_to_ARG = DiagnosticMessage{
    .message = "To convert this file to an ECMAScript module, add the field `\"type\": \"module\"` to '{0s}'.",
    .category = "Message",
    .code = "1482",
};
pub const to_convert_this_file_to_an_ecmascript_module_create_a_local_package_json_file_with_ARG = DiagnosticMessage{
    .message = "To convert this file to an ECMAScript module, create a local package.json file with `{{ \"type\": \"module\" }`.",
    .category = "Message",
    .code = "1483",
};
pub const ARG_is_a_type_and_must_be_imported_using_a_type_only_import_when_verbatimmodulesyntax_is_enabled = DiagnosticMessage{
    .message = "'{0s}' is a type and must be imported using a type-only import when 'verbatimModuleSyntax' is enabled.",
    .category = "Error",
    .code = "1484",
};
pub const ARG_resolves_to_a_type_only_declaration_and_must_be_imported_using_a_type_only_import_when_verbatimmodulesyntax_is_enabled = DiagnosticMessage{
    .message = "'{0s}' resolves to a type-only declaration and must be imported using a type-only import when 'verbatimModuleSyntax' is enabled.",
    .category = "Error",
    .code = "1485",
};
pub const decorator_used_before_export_here = DiagnosticMessage{
    .message = "Decorator used before 'export' here.",
    .category = "Error",
    .code = "1486",
};
pub const octal_escape_sequences_are_not_allowed_use_the_syntax_ARG = DiagnosticMessage{
    .message = "Octal escape sequences are not allowed. Use the syntax '{0s}'.",
    .category = "Error",
    .code = "1487",
};
pub const escape_sequence_ARG_is_not_allowed = DiagnosticMessage{
    .message = "Escape sequence '{0s}' is not allowed.",
    .category = "Error",
    .code = "1488",
};
pub const decimals_with_leading_zeros_are_not_allowed = DiagnosticMessage{
    .message = "Decimals with leading zeros are not allowed.",
    .category = "Error",
    .code = "1489",
};
pub const file_appears_to_be_binary = DiagnosticMessage{
    .message = "File appears to be binary.",
    .category = "Error",
    .code = "1490",
};
pub const ARG_modifier_cannot_appear_on_a_using_declaration = DiagnosticMessage{
    .message = "'{0s}' modifier cannot appear on a 'using' declaration.",
    .category = "Error",
    .code = "1491",
};
pub const ARG_declarations_may_not_have_binding_patterns = DiagnosticMessage{
    .message = "'{0s}' declarations may not have binding patterns.",
    .category = "Error",
    .code = "1492",
};
pub const the_left_hand_side_of_a_for_in_statement_cannot_be_a_using_declaration = DiagnosticMessage{
    .message = "The left-hand side of a 'for...in' statement cannot be a 'using' declaration.",
    .category = "Error",
    .code = "1493",
};
pub const the_left_hand_side_of_a_for_in_statement_cannot_be_an_await_using_declaration = DiagnosticMessage{
    .message = "The left-hand side of a 'for...in' statement cannot be an 'await using' declaration.",
    .category = "Error",
    .code = "1494",
};
pub const ARG_modifier_cannot_appear_on_an_await_using_declaration = DiagnosticMessage{
    .message = "'{0s}' modifier cannot appear on an 'await using' declaration.",
    .category = "Error",
    .code = "1495",
};
pub const identifier_string_literal_or_number_literal_expected = DiagnosticMessage{
    .message = "Identifier, string literal, or number literal expected.",
    .category = "Error",
    .code = "1496",
};
pub const expression_must_be_enclosed_in_parentheses_to_be_used_as_a_decorator = DiagnosticMessage{
    .message = "Expression must be enclosed in parentheses to be used as a decorator.",
    .category = "Error",
    .code = "1497",
};
pub const invalid_syntax_in_decorator = DiagnosticMessage{
    .message = "Invalid syntax in decorator.",
    .category = "Error",
    .code = "1498",
};
pub const unknown_regular_expression_flag = DiagnosticMessage{
    .message = "Unknown regular expression flag.",
    .category = "Error",
    .code = "1499",
};
pub const duplicate_regular_expression_flag = DiagnosticMessage{
    .message = "Duplicate regular expression flag.",
    .category = "Error",
    .code = "1500",
};
pub const this_regular_expression_flag_is_only_available_when_targeting_ARG_or_later = DiagnosticMessage{
    .message = "This regular expression flag is only available when targeting '{0s}' or later.",
    .category = "Error",
    .code = "1501",
};
pub const the_unicode_u_flag_and_the_unicode_sets_v_flag_cannot_be_set_simultaneously = DiagnosticMessage{
    .message = "The Unicode (u) flag and the Unicode Sets (v) flag cannot be set simultaneously.",
    .category = "Error",
    .code = "1502",
};
pub const named_capturing_groups_are_only_available_when_targeting_es2018_or_later = DiagnosticMessage{
    .message = "Named capturing groups are only available when targeting 'ES2018' or later.",
    .category = "Error",
    .code = "1503",
};
pub const subpattern_flags_must_be_present_when_there_is_a_minus_sign = DiagnosticMessage{
    .message = "Subpattern flags must be present when there is a minus sign.",
    .category = "Error",
    .code = "1504",
};
pub const incomplete_quantifier_digit_expected = DiagnosticMessage{
    .message = "Incomplete quantifier. Digit expected.",
    .category = "Error",
    .code = "1505",
};
pub const numbers_out_of_order_in_quantifier = DiagnosticMessage{
    .message = "Numbers out of order in quantifier.",
    .category = "Error",
    .code = "1506",
};
pub const there_is_nothing_available_for_repetition = DiagnosticMessage{
    .message = "There is nothing available for repetition.",
    .category = "Error",
    .code = "1507",
};
pub const unexpected_ARG_did_you_mean_to_escape_it_with_backslash = DiagnosticMessage{
    .message = "Unexpected '{0s}'. Did you mean to escape it with backslash?",
    .category = "Error",
    .code = "1508",
};
pub const this_regular_expression_flag_cannot_be_toggled_within_a_subpattern = DiagnosticMessage{
    .message = "This regular expression flag cannot be toggled within a subpattern.",
    .category = "Error",
    .code = "1509",
};
pub const k_must_be_followed_by_a_capturing_group_name_enclosed_in_angle_brackets = DiagnosticMessage{
    .message = "'\\k' must be followed by a capturing group name enclosed in angle brackets.",
    .category = "Error",
    .code = "1510",
};
pub const q_is_only_available_inside_character_class = DiagnosticMessage{
    .message = "'\\q' is only available inside character class.",
    .category = "Error",
    .code = "1511",
};
pub const c_must_be_followed_by_an_ascii_letter = DiagnosticMessage{
    .message = "'\\c' must be followed by an ASCII letter.",
    .category = "Error",
    .code = "1512",
};
pub const undetermined_character_escape = DiagnosticMessage{
    .message = "Undetermined character escape.",
    .category = "Error",
    .code = "1513",
};
pub const expected_a_capturing_group_name = DiagnosticMessage{
    .message = "Expected a capturing group name.",
    .category = "Error",
    .code = "1514",
};
pub const named_capturing_groups_with_the_same_name_must_be_mutually_exclusive_to_each_other = DiagnosticMessage{
    .message = "Named capturing groups with the same name must be mutually exclusive to each other.",
    .category = "Error",
    .code = "1515",
};
pub const a_character_class_range_must_not_be_bounded_by_another_character_class = DiagnosticMessage{
    .message = "A character class range must not be bounded by another character class.",
    .category = "Error",
    .code = "1516",
};
pub const range_out_of_order_in_character_class = DiagnosticMessage{
    .message = "Range out of order in character class.",
    .category = "Error",
    .code = "1517",
};
pub const anything_that_would_possibly_match_more_than_a_single_character_is_invalid_inside_a_negated_character_class = DiagnosticMessage{
    .message = "Anything that would possibly match more than a single character is invalid inside a negated character class.",
    .category = "Error",
    .code = "1518",
};
pub const operators_must_not_be_mixed_within_a_character_class_wrap_it_in_a_nested_class_instead = DiagnosticMessage{
    .message = "Operators must not be mixed within a character class. Wrap it in a nested class instead.",
    .category = "Error",
    .code = "1519",
};
pub const expected_a_class_set_operand = DiagnosticMessage{
    .message = "Expected a class set operand.",
    .category = "Error",
    .code = "1520",
};
pub const q_must_be_followed_by_string_alternatives_enclosed_in_braces = DiagnosticMessage{
    .message = "'\\q' must be followed by string alternatives enclosed in braces.",
    .category = "Error",
    .code = "1521",
};
pub const a_character_class_must_not_contain_a_reserved_double_punctuator_did_you_mean_to_escape_it_with_backslash = DiagnosticMessage{
    .message = "A character class must not contain a reserved double punctuator. Did you mean to escape it with backslash?",
    .category = "Error",
    .code = "1522",
};
pub const expected_a_unicode_property_name = DiagnosticMessage{
    .message = "Expected a Unicode property name.",
    .category = "Error",
    .code = "1523",
};
pub const unknown_unicode_property_name = DiagnosticMessage{
    .message = "Unknown Unicode property name.",
    .category = "Error",
    .code = "1524",
};
pub const expected_a_unicode_property_value = DiagnosticMessage{
    .message = "Expected a Unicode property value.",
    .category = "Error",
    .code = "1525",
};
pub const unknown_unicode_property_value = DiagnosticMessage{
    .message = "Unknown Unicode property value.",
    .category = "Error",
    .code = "1526",
};
pub const expected_a_unicode_property_name_or_value = DiagnosticMessage{
    .message = "Expected a Unicode property name or value.",
    .category = "Error",
    .code = "1527",
};
pub const any_unicode_property_that_would_possibly_match_more_than_a_single_character_is_only_available_when_the_unicode_sets_v_flag_is_set = DiagnosticMessage{
    .message = "Any Unicode property that would possibly match more than a single character is only available when the Unicode Sets (v) flag is set.",
    .category = "Error",
    .code = "1528",
};
pub const unknown_unicode_property_name_or_value = DiagnosticMessage{
    .message = "Unknown Unicode property name or value.",
    .category = "Error",
    .code = "1529",
};
pub const unicode_property_value_expressions_are_only_available_when_the_unicode_u_flag_or_the_unicode_sets_v_flag_is_set = DiagnosticMessage{
    .message = "Unicode property value expressions are only available when the Unicode (u) flag or the Unicode Sets (v) flag is set.",
    .category = "Error",
    .code = "1530",
};
pub const ARG_must_be_followed_by_a_unicode_property_value_expression_enclosed_in_braces = DiagnosticMessage{
    .message = "'\\{0s}' must be followed by a Unicode property value expression enclosed in braces.",
    .category = "Error",
    .code = "1531",
};
pub const there_is_no_capturing_group_named_ARG_in_this_regular_expression = DiagnosticMessage{
    .message = "There is no capturing group named '{0s}' in this regular expression.",
    .category = "Error",
    .code = "1532",
};
pub const this_backreference_refers_to_a_group_that_does_not_exist_there_are_only_ARG_capturing_groups_in_this_regular_expression = DiagnosticMessage{
    .message = "This backreference refers to a group that does not exist. There are only {0s} capturing groups in this regular expression.",
    .category = "Error",
    .code = "1533",
};
pub const this_backreference_refers_to_a_group_that_does_not_exist_there_are_no_capturing_groups_in_this_regular_expression = DiagnosticMessage{
    .message = "This backreference refers to a group that does not exist. There are no capturing groups in this regular expression.",
    .category = "Error",
    .code = "1534",
};
pub const this_character_cannot_be_escaped_in_a_regular_expression = DiagnosticMessage{
    .message = "This character cannot be escaped in a regular expression.",
    .category = "Error",
    .code = "1535",
};
pub const octal_escape_sequences_and_backreferences_are_not_allowed_in_a_character_class_if_this_was_intended_as_an_escape_sequence_use_the_syntax_ARG_instead = DiagnosticMessage{
    .message = "Octal escape sequences and backreferences are not allowed in a character class. If this was intended as an escape sequence, use the syntax '{0s}' instead.",
    .category = "Error",
    .code = "1536",
};
pub const decimal_escape_sequences_and_backreferences_are_not_allowed_in_a_character_class = DiagnosticMessage{
    .message = "Decimal escape sequences and backreferences are not allowed in a character class.",
    .category = "Error",
    .code = "1537",
};
pub const the_types_of_ARG_are_incompatible_between_these_types = DiagnosticMessage{
    .message = "The types of '{0s}' are incompatible between these types.",
    .category = "Error",
    .code = "2200",
};
pub const the_types_returned_by_ARG_are_incompatible_between_these_types = DiagnosticMessage{
    .message = "The types returned by '{0s}' are incompatible between these types.",
    .category = "Error",
    .code = "2201",
};
pub const call_signature_return_types_ARG_and_ARG_are_incompatible = DiagnosticMessage{
    .message = "Call signature return types '{0s}' and '{1s}' are incompatible.",
    .category = "Error",
    .code = "2202",
};
pub const construct_signature_return_types_ARG_and_ARG_are_incompatible = DiagnosticMessage{
    .message = "Construct signature return types '{0s}' and '{1s}' are incompatible.",
    .category = "Error",
    .code = "2203",
};
pub const call_signatures_with_no_arguments_have_incompatible_return_types_ARG_and_ARG = DiagnosticMessage{
    .message = "Call signatures with no arguments have incompatible return types '{0s}' and '{1s}'.",
    .category = "Error",
    .code = "2204",
};
pub const construct_signatures_with_no_arguments_have_incompatible_return_types_ARG_and_ARG = DiagnosticMessage{
    .message = "Construct signatures with no arguments have incompatible return types '{0s}' and '{1s}'.",
    .category = "Error",
    .code = "2205",
};
pub const the_type_modifier_cannot_be_used_on_a_named_import_when_import_type_is_used_on_its_import_statement = DiagnosticMessage{
    .message = "The 'type' modifier cannot be used on a named import when 'import type' is used on its import statement.",
    .category = "Error",
    .code = "2206",
};
pub const the_type_modifier_cannot_be_used_on_a_named_export_when_export_type_is_used_on_its_export_statement = DiagnosticMessage{
    .message = "The 'type' modifier cannot be used on a named export when 'export type' is used on its export statement.",
    .category = "Error",
    .code = "2207",
};
pub const this_type_parameter_might_need_an_extends_ARG_constraint = DiagnosticMessage{
    .message = "This type parameter might need an `extends {0s}` constraint.",
    .category = "Error",
    .code = "2208",
};
pub const the_project_root_is_ambiguous_but_is_required_to_resolve_export_map_entry_ARG_in_file_ARG_supply_the_rootdir_compiler_option_to_disambiguate = DiagnosticMessage{
    .message = "The project root is ambiguous, but is required to resolve export map entry '{0s}' in file '{1s}'. Supply the `rootDir` compiler option to disambiguate.",
    .category = "Error",
    .code = "2209",
};
pub const the_project_root_is_ambiguous_but_is_required_to_resolve_import_map_entry_ARG_in_file_ARG_supply_the_rootdir_compiler_option_to_disambiguate = DiagnosticMessage{
    .message = "The project root is ambiguous, but is required to resolve import map entry '{0s}' in file '{1s}'. Supply the `rootDir` compiler option to disambiguate.",
    .category = "Error",
    .code = "2210",
};
pub const add_extends_constraint = DiagnosticMessage{
    .message = "Add `extends` constraint.",
    .category = "Message",
    .code = "2211",
};
pub const add_extends_constraint_to_all_type_parameters = DiagnosticMessage{
    .message = "Add `extends` constraint to all type parameters",
    .category = "Message",
    .code = "2212",
};
pub const duplicate_identifier_ARG = DiagnosticMessage{
    .message = "Duplicate identifier '{0s}'.",
    .category = "Error",
    .code = "2300",
};
pub const initializer_of_instance_member_variable_ARG_cannot_reference_identifier_ARG_declared_in_the_constructor = DiagnosticMessage{
    .message = "Initializer of instance member variable '{0s}' cannot reference identifier '{1s}' declared in the constructor.",
    .category = "Error",
    .code = "2301",
};
pub const static_members_cannot_reference_class_type_parameters = DiagnosticMessage{
    .message = "Static members cannot reference class type parameters.",
    .category = "Error",
    .code = "2302",
};
pub const circular_definition_of_import_alias_ARG = DiagnosticMessage{
    .message = "Circular definition of import alias '{0s}'.",
    .category = "Error",
    .code = "2303",
};
pub const cannot_find_name_ARG = DiagnosticMessage{
    .message = "Cannot find name '{0s}'.",
    .category = "Error",
    .code = "2304",
};
pub const module_ARG_has_no_exported_member_ARG = DiagnosticMessage{
    .message = "Module '{0s}' has no exported member '{1s}'.",
    .category = "Error",
    .code = "2305",
};
pub const file_ARG_is_not_a_module = DiagnosticMessage{
    .message = "File '{0s}' is not a module.",
    .category = "Error",
    .code = "2306",
};
pub const cannot_find_module_ARG_or_its_corresponding_type_declarations = DiagnosticMessage{
    .message = "Cannot find module '{0s}' or its corresponding type declarations.",
    .category = "Error",
    .code = "2307",
};
pub const module_ARG_has_already_exported_a_member_named_ARG_consider_explicitly_re_exporting_to_resolve_the_ambiguity = DiagnosticMessage{
    .message = "Module {0s} has already exported a member named '{1s}'. Consider explicitly re-exporting to resolve the ambiguity.",
    .category = "Error",
    .code = "2308",
};
pub const an_export_assignment_cannot_be_used_in_a_module_with_other_exported_elements = DiagnosticMessage{
    .message = "An export assignment cannot be used in a module with other exported elements.",
    .category = "Error",
    .code = "2309",
};
pub const type_ARG_recursively_references_itself_as_a_base_type = DiagnosticMessage{
    .message = "Type '{0s}' recursively references itself as a base type.",
    .category = "Error",
    .code = "2310",
};
pub const cannot_find_name_ARG_did_you_mean_to_write_this_in_an_async_function = DiagnosticMessage{
    .message = "Cannot find name '{0s}'. Did you mean to write this in an async function?",
    .category = "Error",
    .code = "2311",
};
pub const an_interface_can_only_extend_an_object_type_or_intersection_of_object_types_with_statically_known_members = DiagnosticMessage{
    .message = "An interface can only extend an object type or intersection of object types with statically known members.",
    .category = "Error",
    .code = "2312",
};
pub const type_parameter_ARG_has_a_circular_constraint = DiagnosticMessage{
    .message = "Type parameter '{0s}' has a circular constraint.",
    .category = "Error",
    .code = "2313",
};
pub const generic_type_ARG_requires_ARG_type_argument_s = DiagnosticMessage{
    .message = "Generic type '{0s}' requires {1s} type argument(s).",
    .category = "Error",
    .code = "2314",
};
pub const type_ARG_is_not_generic = DiagnosticMessage{
    .message = "Type '{0s}' is not generic.",
    .category = "Error",
    .code = "2315",
};
pub const global_type_ARG_must_be_a_class_or_interface_type = DiagnosticMessage{
    .message = "Global type '{0s}' must be a class or interface type.",
    .category = "Error",
    .code = "2316",
};
pub const global_type_ARG_must_have_ARG_type_parameter_s = DiagnosticMessage{
    .message = "Global type '{0s}' must have {1s} type parameter(s).",
    .category = "Error",
    .code = "2317",
};
pub const cannot_find_global_type_ARG = DiagnosticMessage{
    .message = "Cannot find global type '{0s}'.",
    .category = "Error",
    .code = "2318",
};
pub const named_property_ARG_of_types_ARG_and_ARG_are_not_identical = DiagnosticMessage{
    .message = "Named property '{0s}' of types '{1s}' and '{2s}' are not identical.",
    .category = "Error",
    .code = "2319",
};
pub const interface_ARG_cannot_simultaneously_extend_types_ARG_and_ARG = DiagnosticMessage{
    .message = "Interface '{0s}' cannot simultaneously extend types '{1s}' and '{2s}'.",
    .category = "Error",
    .code = "2320",
};
pub const excessive_stack_depth_comparing_types_ARG_and_ARG = DiagnosticMessage{
    .message = "Excessive stack depth comparing types '{0s}' and '{1s}'.",
    .category = "Error",
    .code = "2321",
};
pub const type_ARG_is_not_assignable_to_type_ARG = DiagnosticMessage{
    .message = "Type '{0s}' is not assignable to type '{1s}'.",
    .category = "Error",
    .code = "2322",
};
pub const cannot_redeclare_exported_variable_ARG = DiagnosticMessage{
    .message = "Cannot redeclare exported variable '{0s}'.",
    .category = "Error",
    .code = "2323",
};
pub const property_ARG_is_missing_in_type_ARG = DiagnosticMessage{
    .message = "Property '{0s}' is missing in type '{1s}'.",
    .category = "Error",
    .code = "2324",
};
pub const property_ARG_is_private_in_type_ARG_but_not_in_type_ARG = DiagnosticMessage{
    .message = "Property '{0s}' is private in type '{1s}' but not in type '{2s}'.",
    .category = "Error",
    .code = "2325",
};
pub const types_of_property_ARG_are_incompatible = DiagnosticMessage{
    .message = "Types of property '{0s}' are incompatible.",
    .category = "Error",
    .code = "2326",
};
pub const property_ARG_is_optional_in_type_ARG_but_required_in_type_ARG = DiagnosticMessage{
    .message = "Property '{0s}' is optional in type '{1s}' but required in type '{2s}'.",
    .category = "Error",
    .code = "2327",
};
pub const types_of_parameters_ARG_and_ARG_are_incompatible = DiagnosticMessage{
    .message = "Types of parameters '{0s}' and '{1s}' are incompatible.",
    .category = "Error",
    .code = "2328",
};
pub const index_signature_for_type_ARG_is_missing_in_type_ARG = DiagnosticMessage{
    .message = "Index signature for type '{0s}' is missing in type '{1s}'.",
    .category = "Error",
    .code = "2329",
};
pub const ARG_and_ARG_index_signatures_are_incompatible = DiagnosticMessage{
    .message = "'{0s}' and '{1s}' index signatures are incompatible.",
    .category = "Error",
    .code = "2330",
};
pub const this_cannot_be_referenced_in_a_module_or_namespace_body = DiagnosticMessage{
    .message = "'this' cannot be referenced in a module or namespace body.",
    .category = "Error",
    .code = "2331",
};
pub const this_cannot_be_referenced_in_current_location = DiagnosticMessage{
    .message = "'this' cannot be referenced in current location.",
    .category = "Error",
    .code = "2332",
};
pub const this_cannot_be_referenced_in_a_static_property_initializer = DiagnosticMessage{
    .message = "'this' cannot be referenced in a static property initializer.",
    .category = "Error",
    .code = "2334",
};
pub const super_can_only_be_referenced_in_a_derived_class = DiagnosticMessage{
    .message = "'super' can only be referenced in a derived class.",
    .category = "Error",
    .code = "2335",
};
pub const super_cannot_be_referenced_in_constructor_arguments = DiagnosticMessage{
    .message = "'super' cannot be referenced in constructor arguments.",
    .category = "Error",
    .code = "2336",
};
pub const super_calls_are_not_permitted_outside_constructors_or_in_nested_functions_inside_constructors = DiagnosticMessage{
    .message = "Super calls are not permitted outside constructors or in nested functions inside constructors.",
    .category = "Error",
    .code = "2337",
};
pub const super_property_access_is_permitted_only_in_a_constructor_member_function_or_member_accessor_of_a_derived_class = DiagnosticMessage{
    .message = "'super' property access is permitted only in a constructor, member function, or member accessor of a derived class.",
    .category = "Error",
    .code = "2338",
};
pub const property_ARG_does_not_exist_on_type_ARG = DiagnosticMessage{
    .message = "Property '{0s}' does not exist on type '{1s}'.",
    .category = "Error",
    .code = "2339",
};
pub const only_public_and_protected_methods_of_the_base_class_are_accessible_via_the_super_keyword = DiagnosticMessage{
    .message = "Only public and protected methods of the base class are accessible via the 'super' keyword.",
    .category = "Error",
    .code = "2340",
};
pub const property_ARG_is_private_and_only_accessible_within_class_ARG = DiagnosticMessage{
    .message = "Property '{0s}' is private and only accessible within class '{1s}'.",
    .category = "Error",
    .code = "2341",
};
pub const this_syntax_requires_an_imported_helper_named_ARG_which_does_not_exist_in_ARG_consider_upgrading_your_version_of_ARG = DiagnosticMessage{
    .message = "This syntax requires an imported helper named '{1s}' which does not exist in '{0s}'. Consider upgrading your version of '{0s}'.",
    .category = "Error",
    .code = "2343",
};
pub const type_ARG_does_not_satisfy_the_constraint_ARG = DiagnosticMessage{
    .message = "Type '{0s}' does not satisfy the constraint '{1s}'.",
    .category = "Error",
    .code = "2344",
};
pub const argument_of_type_ARG_is_not_assignable_to_parameter_of_type_ARG = DiagnosticMessage{
    .message = "Argument of type '{0s}' is not assignable to parameter of type '{1s}'.",
    .category = "Error",
    .code = "2345",
};
pub const untyped_function_calls_may_not_accept_type_arguments = DiagnosticMessage{
    .message = "Untyped function calls may not accept type arguments.",
    .category = "Error",
    .code = "2347",
};
pub const value_of_type_ARG_is_not_callable_did_you_mean_to_include_new = DiagnosticMessage{
    .message = "Value of type '{0s}' is not callable. Did you mean to include 'new'?",
    .category = "Error",
    .code = "2348",
};
pub const this_expression_is_not_callable = DiagnosticMessage{
    .message = "This expression is not callable.",
    .category = "Error",
    .code = "2349",
};
pub const only_a_void_function_can_be_called_with_the_new_keyword = DiagnosticMessage{
    .message = "Only a void function can be called with the 'new' keyword.",
    .category = "Error",
    .code = "2350",
};
pub const this_expression_is_not_constructable = DiagnosticMessage{
    .message = "This expression is not constructable.",
    .category = "Error",
    .code = "2351",
};
pub const conversion_of_type_ARG_to_type_ARG_may_be_a_mistake_because_neither_type_sufficiently_overlaps_with_the_other_if_this_was_intentional_convert_the_expression_to_unknown_first = DiagnosticMessage{
    .message = "Conversion of type '{0s}' to type '{1s}' may be a mistake because neither type sufficiently overlaps with the other. If this was intentional, convert the expression to 'unknown' first.",
    .category = "Error",
    .code = "2352",
};
pub const object_literal_may_only_specify_known_properties_and_ARG_does_not_exist_in_type_ARG = DiagnosticMessage{
    .message = "Object literal may only specify known properties, and '{0s}' does not exist in type '{1s}'.",
    .category = "Error",
    .code = "2353",
};
pub const this_syntax_requires_an_imported_helper_but_module_ARG_cannot_be_found = DiagnosticMessage{
    .message = "This syntax requires an imported helper but module '{0s}' cannot be found.",
    .category = "Error",
    .code = "2354",
};
pub const a_function_whose_declared_type_is_neither_undefined_void_nor_any_must_return_a_value = DiagnosticMessage{
    .message = "A function whose declared type is neither 'undefined', 'void', nor 'any' must return a value.",
    .category = "Error",
    .code = "2355",
};
pub const an_arithmetic_operand_must_be_of_type_any_number_bigint_or_an_enum_type = DiagnosticMessage{
    .message = "An arithmetic operand must be of type 'any', 'number', 'bigint' or an enum type.",
    .category = "Error",
    .code = "2356",
};
pub const the_operand_of_an_increment_or_decrement_operator_must_be_a_variable_or_a_property_access = DiagnosticMessage{
    .message = "The operand of an increment or decrement operator must be a variable or a property access.",
    .category = "Error",
    .code = "2357",
};
pub const the_left_hand_side_of_an_instanceof_expression_must_be_of_type_any_an_object_type_or_a_type_parameter = DiagnosticMessage{
    .message = "The left-hand side of an 'instanceof' expression must be of type 'any', an object type or a type parameter.",
    .category = "Error",
    .code = "2358",
};
pub const the_right_hand_side_of_an_instanceof_expression_must_be_either_of_type_any_a_class_function_or_other_type_assignable_to_the_function_interface_type_or_an_object_type_with_a_symbol_hasinstance_method = DiagnosticMessage{
    .message = "The right-hand side of an 'instanceof' expression must be either of type 'any', a class, function, or other type assignable to the 'Function' interface type, or an object type with a 'Symbol.hasInstance' method.",
    .category = "Error",
    .code = "2359",
};
pub const the_left_hand_side_of_an_arithmetic_operation_must_be_of_type_any_number_bigint_or_an_enum_type = DiagnosticMessage{
    .message = "The left-hand side of an arithmetic operation must be of type 'any', 'number', 'bigint' or an enum type.",
    .category = "Error",
    .code = "2362",
};
pub const the_right_hand_side_of_an_arithmetic_operation_must_be_of_type_any_number_bigint_or_an_enum_type = DiagnosticMessage{
    .message = "The right-hand side of an arithmetic operation must be of type 'any', 'number', 'bigint' or an enum type.",
    .category = "Error",
    .code = "2363",
};
pub const the_left_hand_side_of_an_assignment_expression_must_be_a_variable_or_a_property_access = DiagnosticMessage{
    .message = "The left-hand side of an assignment expression must be a variable or a property access.",
    .category = "Error",
    .code = "2364",
};
pub const operator_ARG_cannot_be_applied_to_types_ARG_and_ARG = DiagnosticMessage{
    .message = "Operator '{0s}' cannot be applied to types '{1s}' and '{2s}'.",
    .category = "Error",
    .code = "2365",
};
pub const function_lacks_ending_return_statement_and_return_type_does_not_include_undefined = DiagnosticMessage{
    .message = "Function lacks ending return statement and return type does not include 'undefined'.",
    .category = "Error",
    .code = "2366",
};
pub const this_comparison_appears_to_be_unintentional_because_the_types_ARG_and_ARG_have_no_overlap = DiagnosticMessage{
    .message = "This comparison appears to be unintentional because the types '{0s}' and '{1s}' have no overlap.",
    .category = "Error",
    .code = "2367",
};
pub const type_parameter_name_cannot_be_ARG = DiagnosticMessage{
    .message = "Type parameter name cannot be '{0s}'.",
    .category = "Error",
    .code = "2368",
};
pub const a_parameter_property_is_only_allowed_in_a_constructor_implementation = DiagnosticMessage{
    .message = "A parameter property is only allowed in a constructor implementation.",
    .category = "Error",
    .code = "2369",
};
pub const a_rest_parameter_must_be_of_an_array_type = DiagnosticMessage{
    .message = "A rest parameter must be of an array type.",
    .category = "Error",
    .code = "2370",
};
pub const a_parameter_initializer_is_only_allowed_in_a_function_or_constructor_implementation = DiagnosticMessage{
    .message = "A parameter initializer is only allowed in a function or constructor implementation.",
    .category = "Error",
    .code = "2371",
};
pub const parameter_ARG_cannot_reference_itself = DiagnosticMessage{
    .message = "Parameter '{0s}' cannot reference itself.",
    .category = "Error",
    .code = "2372",
};
pub const parameter_ARG_cannot_reference_identifier_ARG_declared_after_it = DiagnosticMessage{
    .message = "Parameter '{0s}' cannot reference identifier '{1s}' declared after it.",
    .category = "Error",
    .code = "2373",
};
pub const duplicate_index_signature_for_type_ARG = DiagnosticMessage{
    .message = "Duplicate index signature for type '{0s}'.",
    .category = "Error",
    .code = "2374",
};
pub const type_ARG_is_not_assignable_to_type_ARG_with_exactoptionalpropertytypes_true_consider_adding_undefined_to_the_types_of_the_target_s_properties = DiagnosticMessage{
    .message = "Type '{0s}' is not assignable to type '{1s}' with 'exactOptionalPropertyTypes: true'. Consider adding 'undefined' to the types of the target's properties.",
    .category = "Error",
    .code = "2375",
};
pub const a_super_call_must_be_the_first_statement_in_the_constructor_to_refer_to_super_or_this_when_a_derived_class_contains_initialized_properties_parameter_properties_or_private_identifiers = DiagnosticMessage{
    .message = "A 'super' call must be the first statement in the constructor to refer to 'super' or 'this' when a derived class contains initialized properties, parameter properties, or private identifiers.",
    .category = "Error",
    .code = "2376",
};
pub const constructors_for_derived_classes_must_contain_a_super_call = DiagnosticMessage{
    .message = "Constructors for derived classes must contain a 'super' call.",
    .category = "Error",
    .code = "2377",
};
pub const a_get_accessor_must_return_a_value = DiagnosticMessage{
    .message = "A 'get' accessor must return a value.",
    .category = "Error",
    .code = "2378",
};
pub const argument_of_type_ARG_is_not_assignable_to_parameter_of_type_ARG_with_exactoptionalpropertytypes_true_consider_adding_undefined_to_the_types_of_the_target_s_properties = DiagnosticMessage{
    .message = "Argument of type '{0s}' is not assignable to parameter of type '{1s}' with 'exactOptionalPropertyTypes: true'. Consider adding 'undefined' to the types of the target's properties.",
    .category = "Error",
    .code = "2379",
};
pub const overload_signatures_must_all_be_exported_or_non_exported = DiagnosticMessage{
    .message = "Overload signatures must all be exported or non-exported.",
    .category = "Error",
    .code = "2383",
};
pub const overload_signatures_must_all_be_ambient_or_non_ambient = DiagnosticMessage{
    .message = "Overload signatures must all be ambient or non-ambient.",
    .category = "Error",
    .code = "2384",
};
pub const overload_signatures_must_all_be_public_private_or_protected = DiagnosticMessage{
    .message = "Overload signatures must all be public, private or protected.",
    .category = "Error",
    .code = "2385",
};
pub const overload_signatures_must_all_be_optional_or_required = DiagnosticMessage{
    .message = "Overload signatures must all be optional or required.",
    .category = "Error",
    .code = "2386",
};
pub const function_overload_must_be_static = DiagnosticMessage{
    .message = "Function overload must be static.",
    .category = "Error",
    .code = "2387",
};
pub const function_overload_must_not_be_static = DiagnosticMessage{
    .message = "Function overload must not be static.",
    .category = "Error",
    .code = "2388",
};
pub const function_implementation_name_must_be_ARG = DiagnosticMessage{
    .message = "Function implementation name must be '{0s}'.",
    .category = "Error",
    .code = "2389",
};
pub const constructor_implementation_is_missing = DiagnosticMessage{
    .message = "Constructor implementation is missing.",
    .category = "Error",
    .code = "2390",
};
pub const function_implementation_is_missing_or_not_immediately_following_the_declaration = DiagnosticMessage{
    .message = "Function implementation is missing or not immediately following the declaration.",
    .category = "Error",
    .code = "2391",
};
pub const multiple_constructor_implementations_are_not_allowed = DiagnosticMessage{
    .message = "Multiple constructor implementations are not allowed.",
    .category = "Error",
    .code = "2392",
};
pub const duplicate_function_implementation = DiagnosticMessage{
    .message = "Duplicate function implementation.",
    .category = "Error",
    .code = "2393",
};
pub const this_overload_signature_is_not_compatible_with_its_implementation_signature = DiagnosticMessage{
    .message = "This overload signature is not compatible with its implementation signature.",
    .category = "Error",
    .code = "2394",
};
pub const individual_declarations_in_merged_declaration_ARG_must_be_all_exported_or_all_local = DiagnosticMessage{
    .message = "Individual declarations in merged declaration '{0s}' must be all exported or all local.",
    .category = "Error",
    .code = "2395",
};
pub const duplicate_identifier_arguments_compiler_uses_arguments_to_initialize_rest_parameters = DiagnosticMessage{
    .message = "Duplicate identifier 'arguments'. Compiler uses 'arguments' to initialize rest parameters.",
    .category = "Error",
    .code = "2396",
};
pub const declaration_name_conflicts_with_built_in_global_identifier_ARG = DiagnosticMessage{
    .message = "Declaration name conflicts with built-in global identifier '{0s}'.",
    .category = "Error",
    .code = "2397",
};
pub const constructor_cannot_be_used_as_a_parameter_property_name = DiagnosticMessage{
    .message = "'constructor' cannot be used as a parameter property name.",
    .category = "Error",
    .code = "2398",
};
pub const duplicate_identifier_this_compiler_uses_variable_declaration_this_to_capture_this_reference = DiagnosticMessage{
    .message = "Duplicate identifier '_this'. Compiler uses variable declaration '_this' to capture 'this' reference.",
    .category = "Error",
    .code = "2399",
};
pub const expression_resolves_to_variable_declaration_this_that_compiler_uses_to_capture_this_reference = DiagnosticMessage{
    .message = "Expression resolves to variable declaration '_this' that compiler uses to capture 'this' reference.",
    .category = "Error",
    .code = "2400",
};
pub const a_super_call_must_be_a_root_level_statement_within_a_constructor_of_a_derived_class_that_contains_initialized_properties_parameter_properties_or_private_identifiers = DiagnosticMessage{
    .message = "A 'super' call must be a root-level statement within a constructor of a derived class that contains initialized properties, parameter properties, or private identifiers.",
    .category = "Error",
    .code = "2401",
};
pub const expression_resolves_to_super_that_compiler_uses_to_capture_base_class_reference = DiagnosticMessage{
    .message = "Expression resolves to '_super' that compiler uses to capture base class reference.",
    .category = "Error",
    .code = "2402",
};
pub const subsequent_variable_declarations_must_have_the_same_type_variable_ARG_must_be_of_type_ARG_but_here_has_type_ARG = DiagnosticMessage{
    .message = "Subsequent variable declarations must have the same type.  Variable '{0s}' must be of type '{1s}', but here has type '{2s}'.",
    .category = "Error",
    .code = "2403",
};
pub const the_left_hand_side_of_a_for_in_statement_cannot_use_a_type_annotation = DiagnosticMessage{
    .message = "The left-hand side of a 'for...in' statement cannot use a type annotation.",
    .category = "Error",
    .code = "2404",
};
pub const the_left_hand_side_of_a_for_in_statement_must_be_of_type_string_or_any = DiagnosticMessage{
    .message = "The left-hand side of a 'for...in' statement must be of type 'string' or 'any'.",
    .category = "Error",
    .code = "2405",
};
pub const the_left_hand_side_of_a_for_in_statement_must_be_a_variable_or_a_property_access = DiagnosticMessage{
    .message = "The left-hand side of a 'for...in' statement must be a variable or a property access.",
    .category = "Error",
    .code = "2406",
};
pub const the_right_hand_side_of_a_for_in_statement_must_be_of_type_any_an_object_type_or_a_type_parameter_but_here_has_type_ARG = DiagnosticMessage{
    .message = "The right-hand side of a 'for...in' statement must be of type 'any', an object type or a type parameter, but here has type '{0s}'.",
    .category = "Error",
    .code = "2407",
};
pub const setters_cannot_return_a_value = DiagnosticMessage{
    .message = "Setters cannot return a value.",
    .category = "Error",
    .code = "2408",
};
pub const return_type_of_constructor_signature_must_be_assignable_to_the_instance_type_of_the_class = DiagnosticMessage{
    .message = "Return type of constructor signature must be assignable to the instance type of the class.",
    .category = "Error",
    .code = "2409",
};
pub const the_with_statement_is_not_supported_all_symbols_in_a_with_block_will_have_type_any = DiagnosticMessage{
    .message = "The 'with' statement is not supported. All symbols in a 'with' block will have type 'any'.",
    .category = "Error",
    .code = "2410",
};
pub const type_ARG_is_not_assignable_to_type_ARG_with_exactoptionalpropertytypes_true_consider_adding_undefined_to_the_type_of_the_target = DiagnosticMessage{
    .message = "Type '{0s}' is not assignable to type '{1s}' with 'exactOptionalPropertyTypes: true'. Consider adding 'undefined' to the type of the target.",
    .category = "Error",
    .code = "2412",
};
pub const property_ARG_of_type_ARG_is_not_assignable_to_ARG_index_type_ARG = DiagnosticMessage{
    .message = "Property '{0s}' of type '{1s}' is not assignable to '{2s}' index type '{3s}'.",
    .category = "Error",
    .code = "2411",
};
pub const ARG_index_type_ARG_is_not_assignable_to_ARG_index_type_ARG = DiagnosticMessage{
    .message = "'{0s}' index type '{1s}' is not assignable to '{2s}' index type '{3s}'.",
    .category = "Error",
    .code = "2413",
};
pub const class_name_cannot_be_ARG = DiagnosticMessage{
    .message = "Class name cannot be '{0s}'.",
    .category = "Error",
    .code = "2414",
};
pub const class_ARG_incorrectly_extends_base_class_ARG = DiagnosticMessage{
    .message = "Class '{0s}' incorrectly extends base class '{1s}'.",
    .category = "Error",
    .code = "2415",
};
pub const property_ARG_in_type_ARG_is_not_assignable_to_the_same_property_in_base_type_ARG = DiagnosticMessage{
    .message = "Property '{0s}' in type '{1s}' is not assignable to the same property in base type '{2s}'.",
    .category = "Error",
    .code = "2416",
};
pub const class_static_side_ARG_incorrectly_extends_base_class_static_side_ARG = DiagnosticMessage{
    .message = "Class static side '{0s}' incorrectly extends base class static side '{1s}'.",
    .category = "Error",
    .code = "2417",
};
pub const type_of_computed_property_s_value_is_ARG_which_is_not_assignable_to_type_ARG = DiagnosticMessage{
    .message = "Type of computed property's value is '{0s}', which is not assignable to type '{1s}'.",
    .category = "Error",
    .code = "2418",
};
pub const types_of_construct_signatures_are_incompatible = DiagnosticMessage{
    .message = "Types of construct signatures are incompatible.",
    .category = "Error",
    .code = "2419",
};
pub const class_ARG_incorrectly_implements_interface_ARG = DiagnosticMessage{
    .message = "Class '{0s}' incorrectly implements interface '{1s}'.",
    .category = "Error",
    .code = "2420",
};
pub const a_class_can_only_implement_an_object_type_or_intersection_of_object_types_with_statically_known_members = DiagnosticMessage{
    .message = "A class can only implement an object type or intersection of object types with statically known members.",
    .category = "Error",
    .code = "2422",
};
pub const class_ARG_defines_instance_member_function_ARG_but_extended_class_ARG_defines_it_as_instance_member_accessor = DiagnosticMessage{
    .message = "Class '{0s}' defines instance member function '{1s}', but extended class '{2s}' defines it as instance member accessor.",
    .category = "Error",
    .code = "2423",
};
pub const class_ARG_defines_instance_member_property_ARG_but_extended_class_ARG_defines_it_as_instance_member_function = DiagnosticMessage{
    .message = "Class '{0s}' defines instance member property '{1s}', but extended class '{2s}' defines it as instance member function.",
    .category = "Error",
    .code = "2425",
};
pub const class_ARG_defines_instance_member_accessor_ARG_but_extended_class_ARG_defines_it_as_instance_member_function = DiagnosticMessage{
    .message = "Class '{0s}' defines instance member accessor '{1s}', but extended class '{2s}' defines it as instance member function.",
    .category = "Error",
    .code = "2426",
};
pub const interface_name_cannot_be_ARG = DiagnosticMessage{
    .message = "Interface name cannot be '{0s}'.",
    .category = "Error",
    .code = "2427",
};
pub const all_declarations_of_ARG_must_have_identical_type_parameters = DiagnosticMessage{
    .message = "All declarations of '{0s}' must have identical type parameters.",
    .category = "Error",
    .code = "2428",
};
pub const interface_ARG_incorrectly_extends_interface_ARG = DiagnosticMessage{
    .message = "Interface '{0s}' incorrectly extends interface '{1s}'.",
    .category = "Error",
    .code = "2430",
};
pub const enum_name_cannot_be_ARG = DiagnosticMessage{
    .message = "Enum name cannot be '{0s}'.",
    .category = "Error",
    .code = "2431",
};
pub const in_an_enum_with_multiple_declarations_only_one_declaration_can_omit_an_initializer_for_its_first_enum_element = DiagnosticMessage{
    .message = "In an enum with multiple declarations, only one declaration can omit an initializer for its first enum element.",
    .category = "Error",
    .code = "2432",
};
pub const a_namespace_declaration_cannot_be_in_a_different_file_from_a_class_or_function_with_which_it_is_merged = DiagnosticMessage{
    .message = "A namespace declaration cannot be in a different file from a class or function with which it is merged.",
    .category = "Error",
    .code = "2433",
};
pub const a_namespace_declaration_cannot_be_located_prior_to_a_class_or_function_with_which_it_is_merged = DiagnosticMessage{
    .message = "A namespace declaration cannot be located prior to a class or function with which it is merged.",
    .category = "Error",
    .code = "2434",
};
pub const ambient_modules_cannot_be_nested_in_other_modules_or_namespaces = DiagnosticMessage{
    .message = "Ambient modules cannot be nested in other modules or namespaces.",
    .category = "Error",
    .code = "2435",
};
pub const ambient_module_declaration_cannot_specify_relative_module_name = DiagnosticMessage{
    .message = "Ambient module declaration cannot specify relative module name.",
    .category = "Error",
    .code = "2436",
};
pub const module_ARG_is_hidden_by_a_local_declaration_with_the_same_name = DiagnosticMessage{
    .message = "Module '{0s}' is hidden by a local declaration with the same name.",
    .category = "Error",
    .code = "2437",
};
pub const import_name_cannot_be_ARG = DiagnosticMessage{
    .message = "Import name cannot be '{0s}'.",
    .category = "Error",
    .code = "2438",
};
pub const import_or_export_declaration_in_an_ambient_module_declaration_cannot_reference_module_through_relative_module_name = DiagnosticMessage{
    .message = "Import or export declaration in an ambient module declaration cannot reference module through relative module name.",
    .category = "Error",
    .code = "2439",
};
pub const import_declaration_conflicts_with_local_declaration_of_ARG = DiagnosticMessage{
    .message = "Import declaration conflicts with local declaration of '{0s}'.",
    .category = "Error",
    .code = "2440",
};
pub const duplicate_identifier_ARG_compiler_reserves_name_ARG_in_top_level_scope_of_a_module = DiagnosticMessage{
    .message = "Duplicate identifier '{0s}'. Compiler reserves name '{1s}' in top level scope of a module.",
    .category = "Error",
    .code = "2441",
};
pub const types_have_separate_declarations_of_a_private_property_ARG = DiagnosticMessage{
    .message = "Types have separate declarations of a private property '{0s}'.",
    .category = "Error",
    .code = "2442",
};
pub const property_ARG_is_protected_but_type_ARG_is_not_a_class_derived_from_ARG = DiagnosticMessage{
    .message = "Property '{0s}' is protected but type '{1s}' is not a class derived from '{2s}'.",
    .category = "Error",
    .code = "2443",
};
pub const property_ARG_is_protected_in_type_ARG_but_public_in_type_ARG = DiagnosticMessage{
    .message = "Property '{0s}' is protected in type '{1s}' but public in type '{2s}'.",
    .category = "Error",
    .code = "2444",
};
pub const property_ARG_is_protected_and_only_accessible_within_class_ARG_and_its_subclasses = DiagnosticMessage{
    .message = "Property '{0s}' is protected and only accessible within class '{1s}' and its subclasses.",
    .category = "Error",
    .code = "2445",
};
pub const property_ARG_is_protected_and_only_accessible_through_an_instance_of_class_ARG_this_is_an_instance_of_class_ARG = DiagnosticMessage{
    .message = "Property '{0s}' is protected and only accessible through an instance of class '{1s}'. This is an instance of class '{2s}'.",
    .category = "Error",
    .code = "2446",
};
pub const the_ARG_operator_is_not_allowed_for_boolean_types_consider_using_ARG_instead = DiagnosticMessage{
    .message = "The '{0s}' operator is not allowed for boolean types. Consider using '{1s}' instead.",
    .category = "Error",
    .code = "2447",
};
pub const block_scoped_variable_ARG_used_before_its_declaration = DiagnosticMessage{
    .message = "Block-scoped variable '{0s}' used before its declaration.",
    .category = "Error",
    .code = "2448",
};
pub const class_ARG_used_before_its_declaration = DiagnosticMessage{
    .message = "Class '{0s}' used before its declaration.",
    .category = "Error",
    .code = "2449",
};
pub const enum_ARG_used_before_its_declaration = DiagnosticMessage{
    .message = "Enum '{0s}' used before its declaration.",
    .category = "Error",
    .code = "2450",
};
pub const cannot_redeclare_block_scoped_variable_ARG = DiagnosticMessage{
    .message = "Cannot redeclare block-scoped variable '{0s}'.",
    .category = "Error",
    .code = "2451",
};
pub const an_enum_member_cannot_have_a_numeric_name = DiagnosticMessage{
    .message = "An enum member cannot have a numeric name.",
    .category = "Error",
    .code = "2452",
};
pub const variable_ARG_is_used_before_being_assigned = DiagnosticMessage{
    .message = "Variable '{0s}' is used before being assigned.",
    .category = "Error",
    .code = "2454",
};
pub const type_alias_ARG_circularly_references_itself = DiagnosticMessage{
    .message = "Type alias '{0s}' circularly references itself.",
    .category = "Error",
    .code = "2456",
};
pub const type_alias_name_cannot_be_ARG = DiagnosticMessage{
    .message = "Type alias name cannot be '{0s}'.",
    .category = "Error",
    .code = "2457",
};
pub const an_amd_module_cannot_have_multiple_name_assignments = DiagnosticMessage{
    .message = "An AMD module cannot have multiple name assignments.",
    .category = "Error",
    .code = "2458",
};
pub const module_ARG_declares_ARG_locally_but_it_is_not_exported = DiagnosticMessage{
    .message = "Module '{0s}' declares '{1s}' locally, but it is not exported.",
    .category = "Error",
    .code = "2459",
};
pub const module_ARG_declares_ARG_locally_but_it_is_exported_as_ARG = DiagnosticMessage{
    .message = "Module '{0s}' declares '{1s}' locally, but it is exported as '{2s}'.",
    .category = "Error",
    .code = "2460",
};
pub const type_ARG_is_not_an_array_type = DiagnosticMessage{
    .message = "Type '{0s}' is not an array type.",
    .category = "Error",
    .code = "2461",
};
pub const a_rest_element_must_be_last_in_a_destructuring_pattern = DiagnosticMessage{
    .message = "A rest element must be last in a destructuring pattern.",
    .category = "Error",
    .code = "2462",
};
pub const a_binding_pattern_parameter_cannot_be_optional_in_an_implementation_signature = DiagnosticMessage{
    .message = "A binding pattern parameter cannot be optional in an implementation signature.",
    .category = "Error",
    .code = "2463",
};
pub const a_computed_property_name_must_be_of_type_string_number_symbol_or_any = DiagnosticMessage{
    .message = "A computed property name must be of type 'string', 'number', 'symbol', or 'any'.",
    .category = "Error",
    .code = "2464",
};
pub const this_cannot_be_referenced_in_a_computed_property_name = DiagnosticMessage{
    .message = "'this' cannot be referenced in a computed property name.",
    .category = "Error",
    .code = "2465",
};
pub const super_cannot_be_referenced_in_a_computed_property_name = DiagnosticMessage{
    .message = "'super' cannot be referenced in a computed property name.",
    .category = "Error",
    .code = "2466",
};
pub const a_computed_property_name_cannot_reference_a_type_parameter_from_its_containing_type = DiagnosticMessage{
    .message = "A computed property name cannot reference a type parameter from its containing type.",
    .category = "Error",
    .code = "2467",
};
pub const cannot_find_global_value_ARG = DiagnosticMessage{
    .message = "Cannot find global value '{0s}'.",
    .category = "Error",
    .code = "2468",
};
pub const the_ARG_operator_cannot_be_applied_to_type_symbol = DiagnosticMessage{
    .message = "The '{0s}' operator cannot be applied to type 'symbol'.",
    .category = "Error",
    .code = "2469",
};
pub const spread_operator_in_new_expressions_is_only_available_when_targeting_ecmascript_5_and_higher = DiagnosticMessage{
    .message = "Spread operator in 'new' expressions is only available when targeting ECMAScript 5 and higher.",
    .category = "Error",
    .code = "2472",
};
pub const enum_declarations_must_all_be_const_or_non_const = DiagnosticMessage{
    .message = "Enum declarations must all be const or non-const.",
    .category = "Error",
    .code = "2473",
};
pub const const_enum_member_initializers_must_be_constant_expressions = DiagnosticMessage{
    .message = "const enum member initializers must be constant expressions.",
    .category = "Error",
    .code = "2474",
};
pub const const_enums_can_only_be_used_in_property_or_index_access_expressions_or_the_right_hand_side_of_an_import_declaration_or_export_assignment_or_type_query = DiagnosticMessage{
    .message = "'const' enums can only be used in property or index access expressions or the right hand side of an import declaration or export assignment or type query.",
    .category = "Error",
    .code = "2475",
};
pub const a_const_enum_member_can_only_be_accessed_using_a_string_literal = DiagnosticMessage{
    .message = "A const enum member can only be accessed using a string literal.",
    .category = "Error",
    .code = "2476",
};
pub const const_enum_member_initializer_was_evaluated_to_a_non_finite_value = DiagnosticMessage{
    .message = "'const' enum member initializer was evaluated to a non-finite value.",
    .category = "Error",
    .code = "2477",
};
pub const const_enum_member_initializer_was_evaluated_to_disallowed_value_nan = DiagnosticMessage{
    .message = "'const' enum member initializer was evaluated to disallowed value 'NaN'.",
    .category = "Error",
    .code = "2478",
};
pub const let_is_not_allowed_to_be_used_as_a_name_in_let_or_const_declarations = DiagnosticMessage{
    .message = "'let' is not allowed to be used as a name in 'let' or 'const' declarations.",
    .category = "Error",
    .code = "2480",
};
pub const cannot_initialize_outer_scoped_variable_ARG_in_the_same_scope_as_block_scoped_declaration_ARG = DiagnosticMessage{
    .message = "Cannot initialize outer scoped variable '{0s}' in the same scope as block scoped declaration '{1s}'.",
    .category = "Error",
    .code = "2481",
};
pub const the_left_hand_side_of_a_for_of_statement_cannot_use_a_type_annotation = DiagnosticMessage{
    .message = "The left-hand side of a 'for...of' statement cannot use a type annotation.",
    .category = "Error",
    .code = "2483",
};
pub const export_declaration_conflicts_with_exported_declaration_of_ARG = DiagnosticMessage{
    .message = "Export declaration conflicts with exported declaration of '{0s}'.",
    .category = "Error",
    .code = "2484",
};
pub const the_left_hand_side_of_a_for_of_statement_must_be_a_variable_or_a_property_access = DiagnosticMessage{
    .message = "The left-hand side of a 'for...of' statement must be a variable or a property access.",
    .category = "Error",
    .code = "2487",
};
pub const type_ARG_must_have_a_symbol_iterator_method_that_returns_an_iterator = DiagnosticMessage{
    .message = "Type '{0s}' must have a '[Symbol.iterator]()' method that returns an iterator.",
    .category = "Error",
    .code = "2488",
};
pub const an_iterator_must_have_a_next_method = DiagnosticMessage{
    .message = "An iterator must have a 'next()' method.",
    .category = "Error",
    .code = "2489",
};
pub const the_type_returned_by_the_ARG_method_of_an_iterator_must_have_a_value_property = DiagnosticMessage{
    .message = "The type returned by the '{0s}()' method of an iterator must have a 'value' property.",
    .category = "Error",
    .code = "2490",
};
pub const the_left_hand_side_of_a_for_in_statement_cannot_be_a_destructuring_pattern = DiagnosticMessage{
    .message = "The left-hand side of a 'for...in' statement cannot be a destructuring pattern.",
    .category = "Error",
    .code = "2491",
};
pub const cannot_redeclare_identifier_ARG_in_catch_clause = DiagnosticMessage{
    .message = "Cannot redeclare identifier '{0s}' in catch clause.",
    .category = "Error",
    .code = "2492",
};
pub const tuple_type_ARG_of_length_ARG_has_no_element_at_index_ARG = DiagnosticMessage{
    .message = "Tuple type '{0s}' of length '{1s}' has no element at index '{2s}'.",
    .category = "Error",
    .code = "2493",
};
pub const using_a_string_in_a_for_of_statement_is_only_supported_in_ecmascript_5_and_higher = DiagnosticMessage{
    .message = "Using a string in a 'for...of' statement is only supported in ECMAScript 5 and higher.",
    .category = "Error",
    .code = "2494",
};
pub const type_ARG_is_not_an_array_type_or_a_string_type = DiagnosticMessage{
    .message = "Type '{0s}' is not an array type or a string type.",
    .category = "Error",
    .code = "2495",
};
pub const the_arguments_object_cannot_be_referenced_in_an_arrow_function_in_es5_consider_using_a_standard_function_expression = DiagnosticMessage{
    .message = "The 'arguments' object cannot be referenced in an arrow function in ES5. Consider using a standard function expression.",
    .category = "Error",
    .code = "2496",
};
pub const this_module_can_only_be_referenced_with_ecmascript_imports_exports_by_turning_on_the_ARG_flag_and_referencing_its_default_export = DiagnosticMessage{
    .message = "This module can only be referenced with ECMAScript imports/exports by turning on the '{0s}' flag and referencing its default export.",
    .category = "Error",
    .code = "2497",
};
pub const module_ARG_uses_export_and_cannot_be_used_with_export = DiagnosticMessage{
    .message = "Module '{0s}' uses 'export =' and cannot be used with 'export *'.",
    .category = "Error",
    .code = "2498",
};
pub const an_interface_can_only_extend_an_identifier_qualified_name_with_optional_type_arguments = DiagnosticMessage{
    .message = "An interface can only extend an identifier/qualified-name with optional type arguments.",
    .category = "Error",
    .code = "2499",
};
pub const a_class_can_only_implement_an_identifier_qualified_name_with_optional_type_arguments = DiagnosticMessage{
    .message = "A class can only implement an identifier/qualified-name with optional type arguments.",
    .category = "Error",
    .code = "2500",
};
pub const a_rest_element_cannot_contain_a_binding_pattern = DiagnosticMessage{
    .message = "A rest element cannot contain a binding pattern.",
    .category = "Error",
    .code = "2501",
};
pub const ARG_is_referenced_directly_or_indirectly_in_its_own_type_annotation = DiagnosticMessage{
    .message = "'{0s}' is referenced directly or indirectly in its own type annotation.",
    .category = "Error",
    .code = "2502",
};
pub const cannot_find_namespace_ARG = DiagnosticMessage{
    .message = "Cannot find namespace '{0s}'.",
    .category = "Error",
    .code = "2503",
};
pub const type_ARG_must_have_a_symbol_asynciterator_method_that_returns_an_async_iterator = DiagnosticMessage{
    .message = "Type '{0s}' must have a '[Symbol.asyncIterator]()' method that returns an async iterator.",
    .category = "Error",
    .code = "2504",
};
pub const a_generator_cannot_have_a_void_type_annotation = DiagnosticMessage{
    .message = "A generator cannot have a 'void' type annotation.",
    .category = "Error",
    .code = "2505",
};
pub const ARG_is_referenced_directly_or_indirectly_in_its_own_base_expression = DiagnosticMessage{
    .message = "'{0s}' is referenced directly or indirectly in its own base expression.",
    .category = "Error",
    .code = "2506",
};
pub const type_ARG_is_not_a_constructor_function_type = DiagnosticMessage{
    .message = "Type '{0s}' is not a constructor function type.",
    .category = "Error",
    .code = "2507",
};
pub const no_base_constructor_has_the_specified_number_of_type_arguments = DiagnosticMessage{
    .message = "No base constructor has the specified number of type arguments.",
    .category = "Error",
    .code = "2508",
};
pub const base_constructor_return_type_ARG_is_not_an_object_type_or_intersection_of_object_types_with_statically_known_members = DiagnosticMessage{
    .message = "Base constructor return type '{0s}' is not an object type or intersection of object types with statically known members.",
    .category = "Error",
    .code = "2509",
};
pub const base_constructors_must_all_have_the_same_return_type = DiagnosticMessage{
    .message = "Base constructors must all have the same return type.",
    .category = "Error",
    .code = "2510",
};
pub const cannot_create_an_instance_of_an_abstract_class = DiagnosticMessage{
    .message = "Cannot create an instance of an abstract class.",
    .category = "Error",
    .code = "2511",
};
pub const overload_signatures_must_all_be_abstract_or_non_abstract = DiagnosticMessage{
    .message = "Overload signatures must all be abstract or non-abstract.",
    .category = "Error",
    .code = "2512",
};
pub const abstract_method_ARG_in_class_ARG_cannot_be_accessed_via_super_expression = DiagnosticMessage{
    .message = "Abstract method '{0s}' in class '{1s}' cannot be accessed via super expression.",
    .category = "Error",
    .code = "2513",
};
pub const a_tuple_type_cannot_be_indexed_with_a_negative_value = DiagnosticMessage{
    .message = "A tuple type cannot be indexed with a negative value.",
    .category = "Error",
    .code = "2514",
};
pub const non_abstract_class_ARG_does_not_implement_inherited_abstract_member_ARG_from_class_ARG = DiagnosticMessage{
    .message = "Non-abstract class '{0s}' does not implement inherited abstract member {1s} from class '{2s}'.",
    .category = "Error",
    .code = "2515",
};
pub const all_declarations_of_an_abstract_method_must_be_consecutive = DiagnosticMessage{
    .message = "All declarations of an abstract method must be consecutive.",
    .category = "Error",
    .code = "2516",
};
pub const cannot_assign_an_abstract_constructor_type_to_a_non_abstract_constructor_type = DiagnosticMessage{
    .message = "Cannot assign an abstract constructor type to a non-abstract constructor type.",
    .category = "Error",
    .code = "2517",
};
pub const a_this_based_type_guard_is_not_compatible_with_a_parameter_based_type_guard = DiagnosticMessage{
    .message = "A 'this'-based type guard is not compatible with a parameter-based type guard.",
    .category = "Error",
    .code = "2518",
};
pub const an_async_iterator_must_have_a_next_method = DiagnosticMessage{
    .message = "An async iterator must have a 'next()' method.",
    .category = "Error",
    .code = "2519",
};
pub const duplicate_identifier_ARG_compiler_uses_declaration_ARG_to_support_async_functions = DiagnosticMessage{
    .message = "Duplicate identifier '{0s}'. Compiler uses declaration '{1s}' to support async functions.",
    .category = "Error",
    .code = "2520",
};
pub const the_arguments_object_cannot_be_referenced_in_an_async_function_or_method_in_es5_consider_using_a_standard_function_or_method = DiagnosticMessage{
    .message = "The 'arguments' object cannot be referenced in an async function or method in ES5. Consider using a standard function or method.",
    .category = "Error",
    .code = "2522",
};
pub const yield_expressions_cannot_be_used_in_a_parameter_initializer = DiagnosticMessage{
    .message = "'yield' expressions cannot be used in a parameter initializer.",
    .category = "Error",
    .code = "2523",
};
pub const await_expressions_cannot_be_used_in_a_parameter_initializer = DiagnosticMessage{
    .message = "'await' expressions cannot be used in a parameter initializer.",
    .category = "Error",
    .code = "2524",
};
pub const initializer_provides_no_value_for_this_binding_element_and_the_binding_element_has_no_default_value = DiagnosticMessage{
    .message = "Initializer provides no value for this binding element and the binding element has no default value.",
    .category = "Error",
    .code = "2525",
};
pub const a_this_type_is_available_only_in_a_non_static_member_of_a_class_or_interface = DiagnosticMessage{
    .message = "A 'this' type is available only in a non-static member of a class or interface.",
    .category = "Error",
    .code = "2526",
};
pub const the_inferred_type_of_ARG_references_an_inaccessible_ARG_type_a_type_annotation_is_necessary = DiagnosticMessage{
    .message = "The inferred type of '{0s}' references an inaccessible '{1s}' type. A type annotation is necessary.",
    .category = "Error",
    .code = "2527",
};
pub const a_module_cannot_have_multiple_default_exports = DiagnosticMessage{
    .message = "A module cannot have multiple default exports.",
    .category = "Error",
    .code = "2528",
};
pub const duplicate_identifier_ARG_compiler_reserves_name_ARG_in_top_level_scope_of_a_module_containing_async_functions = DiagnosticMessage{
    .message = "Duplicate identifier '{0s}'. Compiler reserves name '{1s}' in top level scope of a module containing async functions.",
    .category = "Error",
    .code = "2529",
};
pub const property_ARG_is_incompatible_with_index_signature = DiagnosticMessage{
    .message = "Property '{0s}' is incompatible with index signature.",
    .category = "Error",
    .code = "2530",
};
pub const object_is_possibly_null = DiagnosticMessage{
    .message = "Object is possibly 'null'.",
    .category = "Error",
    .code = "2531",
};
pub const object_is_possibly_undefined = DiagnosticMessage{
    .message = "Object is possibly 'undefined'.",
    .category = "Error",
    .code = "2532",
};
pub const object_is_possibly_null_or_undefined = DiagnosticMessage{
    .message = "Object is possibly 'null' or 'undefined'.",
    .category = "Error",
    .code = "2533",
};
pub const a_function_returning_never_cannot_have_a_reachable_end_point = DiagnosticMessage{
    .message = "A function returning 'never' cannot have a reachable end point.",
    .category = "Error",
    .code = "2534",
};
pub const type_ARG_cannot_be_used_to_index_type_ARG = DiagnosticMessage{
    .message = "Type '{0s}' cannot be used to index type '{1s}'.",
    .category = "Error",
    .code = "2536",
};
pub const type_ARG_has_no_matching_index_signature_for_type_ARG = DiagnosticMessage{
    .message = "Type '{0s}' has no matching index signature for type '{1s}'.",
    .category = "Error",
    .code = "2537",
};
pub const type_ARG_cannot_be_used_as_an_index_type = DiagnosticMessage{
    .message = "Type '{0s}' cannot be used as an index type.",
    .category = "Error",
    .code = "2538",
};
pub const cannot_assign_to_ARG_because_it_is_not_a_variable = DiagnosticMessage{
    .message = "Cannot assign to '{0s}' because it is not a variable.",
    .category = "Error",
    .code = "2539",
};
pub const cannot_assign_to_ARG_because_it_is_a_read_only_property = DiagnosticMessage{
    .message = "Cannot assign to '{0s}' because it is a read-only property.",
    .category = "Error",
    .code = "2540",
};
pub const index_signature_in_type_ARG_only_permits_reading = DiagnosticMessage{
    .message = "Index signature in type '{0s}' only permits reading.",
    .category = "Error",
    .code = "2542",
};
pub const duplicate_identifier_newtarget_compiler_uses_variable_declaration_newtarget_to_capture_new_target_meta_property_reference = DiagnosticMessage{
    .message = "Duplicate identifier '_newTarget'. Compiler uses variable declaration '_newTarget' to capture 'new.target' meta-property reference.",
    .category = "Error",
    .code = "2543",
};
pub const expression_resolves_to_variable_declaration_newtarget_that_compiler_uses_to_capture_new_target_meta_property_reference = DiagnosticMessage{
    .message = "Expression resolves to variable declaration '_newTarget' that compiler uses to capture 'new.target' meta-property reference.",
    .category = "Error",
    .code = "2544",
};
pub const a_mixin_class_must_have_a_constructor_with_a_single_rest_parameter_of_type_any = DiagnosticMessage{
    .message = "A mixin class must have a constructor with a single rest parameter of type 'any[]'.",
    .category = "Error",
    .code = "2545",
};
pub const the_type_returned_by_the_ARG_method_of_an_async_iterator_must_be_a_promise_for_a_type_with_a_value_property = DiagnosticMessage{
    .message = "The type returned by the '{0s}()' method of an async iterator must be a promise for a type with a 'value' property.",
    .category = "Error",
    .code = "2547",
};
pub const type_ARG_is_not_an_array_type_or_does_not_have_a_symbol_iterator_method_that_returns_an_iterator = DiagnosticMessage{
    .message = "Type '{0s}' is not an array type or does not have a '[Symbol.iterator]()' method that returns an iterator.",
    .category = "Error",
    .code = "2548",
};
pub const type_ARG_is_not_an_array_type_or_a_string_type_or_does_not_have_a_symbol_iterator_method_that_returns_an_iterator = DiagnosticMessage{
    .message = "Type '{0s}' is not an array type or a string type or does not have a '[Symbol.iterator]()' method that returns an iterator.",
    .category = "Error",
    .code = "2549",
};
pub const property_ARG_does_not_exist_on_type_ARG_do_you_need_to_change_your_target_library_try_changing_the_lib_compiler_option_to_ARG_or_later = DiagnosticMessage{
    .message = "Property '{0s}' does not exist on type '{1s}'. Do you need to change your target library? Try changing the 'lib' compiler option to '{2s}' or later.",
    .category = "Error",
    .code = "2550",
};
pub const property_ARG_does_not_exist_on_type_ARG_did_you_mean_ARG = DiagnosticMessage{
    .message = "Property '{0s}' does not exist on type '{1s}'. Did you mean '{2s}'?",
    .category = "Error",
    .code = "2551",
};
pub const cannot_find_name_ARG_did_you_mean_ARG = DiagnosticMessage{
    .message = "Cannot find name '{0s}'. Did you mean '{1s}'?",
    .category = "Error",
    .code = "2552",
};
pub const computed_values_are_not_permitted_in_an_enum_with_string_valued_members = DiagnosticMessage{
    .message = "Computed values are not permitted in an enum with string valued members.",
    .category = "Error",
    .code = "2553",
};
pub const expected_ARG_arguments_but_got_ARG = DiagnosticMessage{
    .message = "Expected {0s} arguments, but got {1s}.",
    .category = "Error",
    .code = "2554",
};
pub const expected_at_least_ARG_arguments_but_got_ARG = DiagnosticMessage{
    .message = "Expected at least {0s} arguments, but got {1s}.",
    .category = "Error",
    .code = "2555",
};
pub const a_spread_argument_must_either_have_a_tuple_type_or_be_passed_to_a_rest_parameter = DiagnosticMessage{
    .message = "A spread argument must either have a tuple type or be passed to a rest parameter.",
    .category = "Error",
    .code = "2556",
};
pub const expected_ARG_type_arguments_but_got_ARG = DiagnosticMessage{
    .message = "Expected {0s} type arguments, but got {1s}.",
    .category = "Error",
    .code = "2558",
};
pub const type_ARG_has_no_properties_in_common_with_type_ARG = DiagnosticMessage{
    .message = "Type '{0s}' has no properties in common with type '{1s}'.",
    .category = "Error",
    .code = "2559",
};
pub const value_of_type_ARG_has_no_properties_in_common_with_type_ARG_did_you_mean_to_call_it = DiagnosticMessage{
    .message = "Value of type '{0s}' has no properties in common with type '{1s}'. Did you mean to call it?",
    .category = "Error",
    .code = "2560",
};
pub const object_literal_may_only_specify_known_properties_but_ARG_does_not_exist_in_type_ARG_did_you_mean_to_write_ARG = DiagnosticMessage{
    .message = "Object literal may only specify known properties, but '{0s}' does not exist in type '{1s}'. Did you mean to write '{2s}'?",
    .category = "Error",
    .code = "2561",
};
pub const base_class_expressions_cannot_reference_class_type_parameters = DiagnosticMessage{
    .message = "Base class expressions cannot reference class type parameters.",
    .category = "Error",
    .code = "2562",
};
pub const the_containing_function_or_module_body_is_too_large_for_control_flow_analysis = DiagnosticMessage{
    .message = "The containing function or module body is too large for control flow analysis.",
    .category = "Error",
    .code = "2563",
};
pub const property_ARG_has_no_initializer_and_is_not_definitely_assigned_in_the_constructor = DiagnosticMessage{
    .message = "Property '{0s}' has no initializer and is not definitely assigned in the constructor.",
    .category = "Error",
    .code = "2564",
};
pub const property_ARG_is_used_before_being_assigned = DiagnosticMessage{
    .message = "Property '{0s}' is used before being assigned.",
    .category = "Error",
    .code = "2565",
};
pub const a_rest_element_cannot_have_a_property_name = DiagnosticMessage{
    .message = "A rest element cannot have a property name.",
    .category = "Error",
    .code = "2566",
};
pub const enum_declarations_can_only_merge_with_namespace_or_other_enum_declarations = DiagnosticMessage{
    .message = "Enum declarations can only merge with namespace or other enum declarations.",
    .category = "Error",
    .code = "2567",
};
pub const property_ARG_may_not_exist_on_type_ARG_did_you_mean_ARG = DiagnosticMessage{
    .message = "Property '{0s}' may not exist on type '{1s}'. Did you mean '{2s}'?",
    .category = "Error",
    .code = "2568",
};
pub const could_not_find_name_ARG_did_you_mean_ARG = DiagnosticMessage{
    .message = "Could not find name '{0s}'. Did you mean '{1s}'?",
    .category = "Error",
    .code = "2570",
};
pub const object_is_of_type_unknown = DiagnosticMessage{
    .message = "Object is of type 'unknown'.",
    .category = "Error",
    .code = "2571",
};
pub const a_rest_element_type_must_be_an_array_type = DiagnosticMessage{
    .message = "A rest element type must be an array type.",
    .category = "Error",
    .code = "2574",
};
pub const no_overload_expects_ARG_arguments_but_overloads_do_exist_that_expect_either_ARG_or_ARG_arguments = DiagnosticMessage{
    .message = "No overload expects {0s} arguments, but overloads do exist that expect either {1s} or {2s} arguments.",
    .category = "Error",
    .code = "2575",
};
pub const property_ARG_does_not_exist_on_type_ARG_did_you_mean_to_access_the_static_member_ARG_instead = DiagnosticMessage{
    .message = "Property '{0s}' does not exist on type '{1s}'. Did you mean to access the static member '{2s}' instead?",
    .category = "Error",
    .code = "2576",
};
pub const return_type_annotation_circularly_references_itself = DiagnosticMessage{
    .message = "Return type annotation circularly references itself.",
    .category = "Error",
    .code = "2577",
};
pub const unused_ts_expect_error_directive = DiagnosticMessage{
    .message = "Unused '@ts-expect-error' directive.",
    .category = "Error",
    .code = "2578",
};
pub const cannot_find_name_ARG_do_you_need_to_install_type_definitions_for_node_try_npm_i_save_dev_types_node = DiagnosticMessage{
    .message = "Cannot find name '{0s}'. Do you need to install type definitions for node? Try `npm i --save-dev @types/node`.",
    .category = "Error",
    .code = "2580",
};
pub const cannot_find_name_ARG_do_you_need_to_install_type_definitions_for_jquery_try_npm_i_save_dev_types_jquery = DiagnosticMessage{
    .message = "Cannot find name '{0s}'. Do you need to install type definitions for jQuery? Try `npm i --save-dev @types/jquery`.",
    .category = "Error",
    .code = "2581",
};
pub const cannot_find_name_ARG_do_you_need_to_install_type_definitions_for_a_test_runner_try_npm_i_save_dev_types_jest_or_npm_i_save_dev_types_mocha = DiagnosticMessage{
    .message = "Cannot find name '{0s}'. Do you need to install type definitions for a test runner? Try `npm i --save-dev @types/jest` or `npm i --save-dev @types/mocha`.",
    .category = "Error",
    .code = "2582",
};
pub const cannot_find_name_ARG_do_you_need_to_change_your_target_library_try_changing_the_lib_compiler_option_to_ARG_or_later = DiagnosticMessage{
    .message = "Cannot find name '{0s}'. Do you need to change your target library? Try changing the 'lib' compiler option to '{1s}' or later.",
    .category = "Error",
    .code = "2583",
};
pub const cannot_find_name_ARG_do_you_need_to_change_your_target_library_try_changing_the_lib_compiler_option_to_include_dom = DiagnosticMessage{
    .message = "Cannot find name '{0s}'. Do you need to change your target library? Try changing the 'lib' compiler option to include 'dom'.",
    .category = "Error",
    .code = "2584",
};
pub const ARG_only_refers_to_a_type_but_is_being_used_as_a_value_here_do_you_need_to_change_your_target_library_try_changing_the_lib_compiler_option_to_es2015_or_later = DiagnosticMessage{
    .message = "'{0s}' only refers to a type, but is being used as a value here. Do you need to change your target library? Try changing the 'lib' compiler option to es2015 or later.",
    .category = "Error",
    .code = "2585",
};
pub const cannot_assign_to_ARG_because_it_is_a_constant = DiagnosticMessage{
    .message = "Cannot assign to '{0s}' because it is a constant.",
    .category = "Error",
    .code = "2588",
};
pub const type_instantiation_is_excessively_deep_and_possibly_infinite = DiagnosticMessage{
    .message = "Type instantiation is excessively deep and possibly infinite.",
    .category = "Error",
    .code = "2589",
};
pub const expression_produces_a_union_type_that_is_too_complex_to_represent = DiagnosticMessage{
    .message = "Expression produces a union type that is too complex to represent.",
    .category = "Error",
    .code = "2590",
};
pub const cannot_find_name_ARG_do_you_need_to_install_type_definitions_for_node_try_npm_i_save_dev_types_node_and_then_add_node_to_the_types_field_in_your_tsconfig = DiagnosticMessage{
    .message = "Cannot find name '{0s}'. Do you need to install type definitions for node? Try `npm i --save-dev @types/node` and then add 'node' to the types field in your tsconfig.",
    .category = "Error",
    .code = "2591",
};
pub const cannot_find_name_ARG_do_you_need_to_install_type_definitions_for_jquery_try_npm_i_save_dev_types_jquery_and_then_add_jquery_to_the_types_field_in_your_tsconfig = DiagnosticMessage{
    .message = "Cannot find name '{0s}'. Do you need to install type definitions for jQuery? Try `npm i --save-dev @types/jquery` and then add 'jquery' to the types field in your tsconfig.",
    .category = "Error",
    .code = "2592",
};
pub const cannot_find_name_ARG_do_you_need_to_install_type_definitions_for_a_test_runner_try_npm_i_save_dev_types_jest_or_npm_i_save_dev_types_mocha_and_then_add_jest_or_mocha_to_the_types_field_in_your_tsconfig = DiagnosticMessage{
    .message = "Cannot find name '{0s}'. Do you need to install type definitions for a test runner? Try `npm i --save-dev @types/jest` or `npm i --save-dev @types/mocha` and then add 'jest' or 'mocha' to the types field in your tsconfig.",
    .category = "Error",
    .code = "2593",
};
pub const this_module_is_declared_with_export_and_can_only_be_used_with_a_default_import_when_using_the_ARG_flag = DiagnosticMessage{
    .message = "This module is declared with 'export =', and can only be used with a default import when using the '{0s}' flag.",
    .category = "Error",
    .code = "2594",
};
pub const ARG_can_only_be_imported_by_using_a_default_import = DiagnosticMessage{
    .message = "'{0s}' can only be imported by using a default import.",
    .category = "Error",
    .code = "2595",
};
pub const ARG_can_only_be_imported_by_turning_on_the_esmoduleinterop_flag_and_using_a_default_import = DiagnosticMessage{
    .message = "'{0s}' can only be imported by turning on the 'esModuleInterop' flag and using a default import.",
    .category = "Error",
    .code = "2596",
};
pub const ARG_can_only_be_imported_by_using_a_require_call_or_by_using_a_default_import = DiagnosticMessage{
    .message = "'{0s}' can only be imported by using a 'require' call or by using a default import.",
    .category = "Error",
    .code = "2597",
};
pub const ARG_can_only_be_imported_by_using_a_require_call_or_by_turning_on_the_esmoduleinterop_flag_and_using_a_default_import = DiagnosticMessage{
    .message = "'{0s}' can only be imported by using a 'require' call or by turning on the 'esModuleInterop' flag and using a default import.",
    .category = "Error",
    .code = "2598",
};
pub const jsx_element_implicitly_has_type_any_because_the_global_type_jsx_element_does_not_exist = DiagnosticMessage{
    .message = "JSX element implicitly has type 'any' because the global type 'JSX.Element' does not exist.",
    .category = "Error",
    .code = "2602",
};
pub const property_ARG_in_type_ARG_is_not_assignable_to_type_ARG = DiagnosticMessage{
    .message = "Property '{0s}' in type '{1s}' is not assignable to type '{2s}'.",
    .category = "Error",
    .code = "2603",
};
pub const jsx_element_type_ARG_does_not_have_any_construct_or_call_signatures = DiagnosticMessage{
    .message = "JSX element type '{0s}' does not have any construct or call signatures.",
    .category = "Error",
    .code = "2604",
};
pub const property_ARG_of_jsx_spread_attribute_is_not_assignable_to_target_property = DiagnosticMessage{
    .message = "Property '{0s}' of JSX spread attribute is not assignable to target property.",
    .category = "Error",
    .code = "2606",
};
pub const jsx_element_class_does_not_support_attributes_because_it_does_not_have_a_ARG_property = DiagnosticMessage{
    .message = "JSX element class does not support attributes because it does not have a '{0s}' property.",
    .category = "Error",
    .code = "2607",
};
pub const the_global_type_jsx_ARG_may_not_have_more_than_one_property = DiagnosticMessage{
    .message = "The global type 'JSX.{0s}' may not have more than one property.",
    .category = "Error",
    .code = "2608",
};
pub const jsx_spread_child_must_be_an_array_type = DiagnosticMessage{
    .message = "JSX spread child must be an array type.",
    .category = "Error",
    .code = "2609",
};
pub const ARG_is_defined_as_an_accessor_in_class_ARG_but_is_overridden_here_in_ARG_as_an_instance_property = DiagnosticMessage{
    .message = "'{0s}' is defined as an accessor in class '{1s}', but is overridden here in '{2s}' as an instance property.",
    .category = "Error",
    .code = "2610",
};
pub const ARG_is_defined_as_a_property_in_class_ARG_but_is_overridden_here_in_ARG_as_an_accessor = DiagnosticMessage{
    .message = "'{0s}' is defined as a property in class '{1s}', but is overridden here in '{2s}' as an accessor.",
    .category = "Error",
    .code = "2611",
};
pub const property_ARG_will_overwrite_the_base_property_in_ARG_if_this_is_intentional_add_an_initializer_otherwise_add_a_declare_modifier_or_remove_the_redundant_declaration = DiagnosticMessage{
    .message = "Property '{0s}' will overwrite the base property in '{1s}'. If this is intentional, add an initializer. Otherwise, add a 'declare' modifier or remove the redundant declaration.",
    .category = "Error",
    .code = "2612",
};
pub const module_ARG_has_no_default_export_did_you_mean_to_use_import_ARG_from_ARG_instead = DiagnosticMessage{
    .message = "Module '{0s}' has no default export. Did you mean to use 'import {{ {1s} } from {0s}' instead?",
    .category = "Error",
    .code = "2613",
};
pub const module_ARG_has_no_exported_member_ARG_did_you_mean_to_use_import_ARG_from_ARG_instead = DiagnosticMessage{
    .message = "Module '{0s}' has no exported member '{1s}'. Did you mean to use 'import {1s} from {0s}' instead?",
    .category = "Error",
    .code = "2614",
};
pub const type_of_property_ARG_circularly_references_itself_in_mapped_type_ARG = DiagnosticMessage{
    .message = "Type of property '{0s}' circularly references itself in mapped type '{1s}'.",
    .category = "Error",
    .code = "2615",
};
pub const ARG_can_only_be_imported_by_using_import_ARG_require_ARG_or_a_default_import = DiagnosticMessage{
    .message = "'{0s}' can only be imported by using 'import {1s} = require({2s})' or a default import.",
    .category = "Error",
    .code = "2616",
};
pub const ARG_can_only_be_imported_by_using_import_ARG_require_ARG_or_by_turning_on_the_esmoduleinterop_flag_and_using_a_default_import = DiagnosticMessage{
    .message = "'{0s}' can only be imported by using 'import {1s} = require({2s})' or by turning on the 'esModuleInterop' flag and using a default import.",
    .category = "Error",
    .code = "2617",
};
pub const source_has_ARG_element_s_but_target_requires_ARG = DiagnosticMessage{
    .message = "Source has {0s} element(s) but target requires {1s}.",
    .category = "Error",
    .code = "2618",
};
pub const source_has_ARG_element_s_but_target_allows_only_ARG = DiagnosticMessage{
    .message = "Source has {0s} element(s) but target allows only {1s}.",
    .category = "Error",
    .code = "2619",
};
pub const target_requires_ARG_element_s_but_source_may_have_fewer = DiagnosticMessage{
    .message = "Target requires {0s} element(s) but source may have fewer.",
    .category = "Error",
    .code = "2620",
};
pub const target_allows_only_ARG_element_s_but_source_may_have_more = DiagnosticMessage{
    .message = "Target allows only {0s} element(s) but source may have more.",
    .category = "Error",
    .code = "2621",
};
pub const source_provides_no_match_for_required_element_at_position_ARG_in_target = DiagnosticMessage{
    .message = "Source provides no match for required element at position {0s} in target.",
    .category = "Error",
    .code = "2623",
};
pub const source_provides_no_match_for_variadic_element_at_position_ARG_in_target = DiagnosticMessage{
    .message = "Source provides no match for variadic element at position {0s} in target.",
    .category = "Error",
    .code = "2624",
};
pub const variadic_element_at_position_ARG_in_source_does_not_match_element_at_position_ARG_in_target = DiagnosticMessage{
    .message = "Variadic element at position {0s} in source does not match element at position {1s} in target.",
    .category = "Error",
    .code = "2625",
};
pub const type_at_position_ARG_in_source_is_not_compatible_with_type_at_position_ARG_in_target = DiagnosticMessage{
    .message = "Type at position {0s} in source is not compatible with type at position {1s} in target.",
    .category = "Error",
    .code = "2626",
};
pub const type_at_positions_ARG_through_ARG_in_source_is_not_compatible_with_type_at_position_ARG_in_target = DiagnosticMessage{
    .message = "Type at positions {0s} through {1s} in source is not compatible with type at position {2s} in target.",
    .category = "Error",
    .code = "2627",
};
pub const cannot_assign_to_ARG_because_it_is_an_enum = DiagnosticMessage{
    .message = "Cannot assign to '{0s}' because it is an enum.",
    .category = "Error",
    .code = "2628",
};
pub const cannot_assign_to_ARG_because_it_is_a_class = DiagnosticMessage{
    .message = "Cannot assign to '{0s}' because it is a class.",
    .category = "Error",
    .code = "2629",
};
pub const cannot_assign_to_ARG_because_it_is_a_function = DiagnosticMessage{
    .message = "Cannot assign to '{0s}' because it is a function.",
    .category = "Error",
    .code = "2630",
};
pub const cannot_assign_to_ARG_because_it_is_a_namespace = DiagnosticMessage{
    .message = "Cannot assign to '{0s}' because it is a namespace.",
    .category = "Error",
    .code = "2631",
};
pub const cannot_assign_to_ARG_because_it_is_an_import = DiagnosticMessage{
    .message = "Cannot assign to '{0s}' because it is an import.",
    .category = "Error",
    .code = "2632",
};
pub const jsx_property_access_expressions_cannot_include_jsx_namespace_names = DiagnosticMessage{
    .message = "JSX property access expressions cannot include JSX namespace names",
    .category = "Error",
    .code = "2633",
};
pub const ARG_index_signatures_are_incompatible = DiagnosticMessage{
    .message = "'{0s}' index signatures are incompatible.",
    .category = "Error",
    .code = "2634",
};
pub const type_ARG_has_no_signatures_for_which_the_type_argument_list_is_applicable = DiagnosticMessage{
    .message = "Type '{0s}' has no signatures for which the type argument list is applicable.",
    .category = "Error",
    .code = "2635",
};
pub const type_ARG_is_not_assignable_to_type_ARG_as_implied_by_variance_annotation = DiagnosticMessage{
    .message = "Type '{0s}' is not assignable to type '{1s}' as implied by variance annotation.",
    .category = "Error",
    .code = "2636",
};
pub const variance_annotations_are_only_supported_in_type_aliases_for_object_function_constructor_and_mapped_types = DiagnosticMessage{
    .message = "Variance annotations are only supported in type aliases for object, function, constructor, and mapped types.",
    .category = "Error",
    .code = "2637",
};
pub const type_ARG_may_represent_a_primitive_value_which_is_not_permitted_as_the_right_operand_of_the_in_operator = DiagnosticMessage{
    .message = "Type '{0s}' may represent a primitive value, which is not permitted as the right operand of the 'in' operator.",
    .category = "Error",
    .code = "2638",
};
pub const react_components_cannot_include_jsx_namespace_names = DiagnosticMessage{
    .message = "React components cannot include JSX namespace names",
    .category = "Error",
    .code = "2639",
};
pub const cannot_augment_module_ARG_with_value_exports_because_it_resolves_to_a_non_module_entity = DiagnosticMessage{
    .message = "Cannot augment module '{0s}' with value exports because it resolves to a non-module entity.",
    .category = "Error",
    .code = "2649",
};
pub const non_abstract_class_expression_is_missing_implementations_for_the_following_members_of_ARG_ARG_and_ARG_more = DiagnosticMessage{
    .message = "Non-abstract class expression is missing implementations for the following members of '{0s}': {1s} and {2s} more.",
    .category = "Error",
    .code = "2650",
};
pub const a_member_initializer_in_a_enum_declaration_cannot_reference_members_declared_after_it_including_members_defined_in_other_enums = DiagnosticMessage{
    .message = "A member initializer in a enum declaration cannot reference members declared after it, including members defined in other enums.",
    .category = "Error",
    .code = "2651",
};
pub const merged_declaration_ARG_cannot_include_a_default_export_declaration_consider_adding_a_separate_export_default_ARG_declaration_instead = DiagnosticMessage{
    .message = "Merged declaration '{0s}' cannot include a default export declaration. Consider adding a separate 'export default {0s}' declaration instead.",
    .category = "Error",
    .code = "2652",
};
pub const non_abstract_class_expression_does_not_implement_inherited_abstract_member_ARG_from_class_ARG = DiagnosticMessage{
    .message = "Non-abstract class expression does not implement inherited abstract member '{0s}' from class '{1s}'.",
    .category = "Error",
    .code = "2653",
};
pub const non_abstract_class_ARG_is_missing_implementations_for_the_following_members_of_ARG_ARG = DiagnosticMessage{
    .message = "Non-abstract class '{0s}' is missing implementations for the following members of '{1s}': {2s}.",
    .category = "Error",
    .code = "2654",
};
pub const non_abstract_class_ARG_is_missing_implementations_for_the_following_members_of_ARG_ARG_and_ARG_more = DiagnosticMessage{
    .message = "Non-abstract class '{0s}' is missing implementations for the following members of '{1s}': {2s} and {3s} more.",
    .category = "Error",
    .code = "2655",
};
pub const non_abstract_class_expression_is_missing_implementations_for_the_following_members_of_ARG_ARG = DiagnosticMessage{
    .message = "Non-abstract class expression is missing implementations for the following members of '{0s}': {1s}.",
    .category = "Error",
    .code = "2656",
};
pub const jsx_expressions_must_have_one_parent_element = DiagnosticMessage{
    .message = "JSX expressions must have one parent element.",
    .category = "Error",
    .code = "2657",
};
pub const type_ARG_provides_no_match_for_the_signature_ARG = DiagnosticMessage{
    .message = "Type '{0s}' provides no match for the signature '{1s}'.",
    .category = "Error",
    .code = "2658",
};
pub const super_is_only_allowed_in_members_of_object_literal_expressions_when_option_target_is_es2015_or_higher = DiagnosticMessage{
    .message = "'super' is only allowed in members of object literal expressions when option 'target' is 'ES2015' or higher.",
    .category = "Error",
    .code = "2659",
};
pub const super_can_only_be_referenced_in_members_of_derived_classes_or_object_literal_expressions = DiagnosticMessage{
    .message = "'super' can only be referenced in members of derived classes or object literal expressions.",
    .category = "Error",
    .code = "2660",
};
pub const cannot_export_ARG_only_local_declarations_can_be_exported_from_a_module = DiagnosticMessage{
    .message = "Cannot export '{0s}'. Only local declarations can be exported from a module.",
    .category = "Error",
    .code = "2661",
};
pub const cannot_find_name_ARG_did_you_mean_the_static_member_ARG_ARG = DiagnosticMessage{
    .message = "Cannot find name '{0s}'. Did you mean the static member '{1s}.{0s}'?",
    .category = "Error",
    .code = "2662",
};
pub const cannot_find_name_ARG_did_you_mean_the_instance_member_this_ARG = DiagnosticMessage{
    .message = "Cannot find name '{0s}'. Did you mean the instance member 'this.{0s}'?",
    .category = "Error",
    .code = "2663",
};
pub const invalid_module_name_in_augmentation_module_ARG_cannot_be_found = DiagnosticMessage{
    .message = "Invalid module name in augmentation, module '{0s}' cannot be found.",
    .category = "Error",
    .code = "2664",
};
pub const invalid_module_name_in_augmentation_module_ARG_resolves_to_an_untyped_module_at_ARG_which_cannot_be_augmented = DiagnosticMessage{
    .message = "Invalid module name in augmentation. Module '{0s}' resolves to an untyped module at '{1s}', which cannot be augmented.",
    .category = "Error",
    .code = "2665",
};
pub const exports_and_export_assignments_are_not_permitted_in_module_augmentations = DiagnosticMessage{
    .message = "Exports and export assignments are not permitted in module augmentations.",
    .category = "Error",
    .code = "2666",
};
pub const imports_are_not_permitted_in_module_augmentations_consider_moving_them_to_the_enclosing_external_module = DiagnosticMessage{
    .message = "Imports are not permitted in module augmentations. Consider moving them to the enclosing external module.",
    .category = "Error",
    .code = "2667",
};
pub const export_modifier_cannot_be_applied_to_ambient_modules_and_module_augmentations_since_they_are_always_visible = DiagnosticMessage{
    .message = "'export' modifier cannot be applied to ambient modules and module augmentations since they are always visible.",
    .category = "Error",
    .code = "2668",
};
pub const augmentations_for_the_global_scope_can_only_be_directly_nested_in_external_modules_or_ambient_module_declarations = DiagnosticMessage{
    .message = "Augmentations for the global scope can only be directly nested in external modules or ambient module declarations.",
    .category = "Error",
    .code = "2669",
};
pub const augmentations_for_the_global_scope_should_have_declare_modifier_unless_they_appear_in_already_ambient_context = DiagnosticMessage{
    .message = "Augmentations for the global scope should have 'declare' modifier unless they appear in already ambient context.",
    .category = "Error",
    .code = "2670",
};
pub const cannot_augment_module_ARG_because_it_resolves_to_a_non_module_entity = DiagnosticMessage{
    .message = "Cannot augment module '{0s}' because it resolves to a non-module entity.",
    .category = "Error",
    .code = "2671",
};
pub const cannot_assign_a_ARG_constructor_type_to_a_ARG_constructor_type = DiagnosticMessage{
    .message = "Cannot assign a '{0s}' constructor type to a '{1s}' constructor type.",
    .category = "Error",
    .code = "2672",
};
pub const constructor_of_class_ARG_is_private_and_only_accessible_within_the_class_declaration = DiagnosticMessage{
    .message = "Constructor of class '{0s}' is private and only accessible within the class declaration.",
    .category = "Error",
    .code = "2673",
};
pub const constructor_of_class_ARG_is_protected_and_only_accessible_within_the_class_declaration = DiagnosticMessage{
    .message = "Constructor of class '{0s}' is protected and only accessible within the class declaration.",
    .category = "Error",
    .code = "2674",
};
pub const cannot_extend_a_class_ARG_class_constructor_is_marked_as_private = DiagnosticMessage{
    .message = "Cannot extend a class '{0s}'. Class constructor is marked as private.",
    .category = "Error",
    .code = "2675",
};
pub const accessors_must_both_be_abstract_or_non_abstract = DiagnosticMessage{
    .message = "Accessors must both be abstract or non-abstract.",
    .category = "Error",
    .code = "2676",
};
pub const a_type_predicate_s_type_must_be_assignable_to_its_parameter_s_type = DiagnosticMessage{
    .message = "A type predicate's type must be assignable to its parameter's type.",
    .category = "Error",
    .code = "2677",
};
pub const type_ARG_is_not_comparable_to_type_ARG = DiagnosticMessage{
    .message = "Type '{0s}' is not comparable to type '{1s}'.",
    .category = "Error",
    .code = "2678",
};
pub const a_function_that_is_called_with_the_new_keyword_cannot_have_a_this_type_that_is_void = DiagnosticMessage{
    .message = "A function that is called with the 'new' keyword cannot have a 'this' type that is 'void'.",
    .category = "Error",
    .code = "2679",
};
pub const a_ARG_parameter_must_be_the_first_parameter = DiagnosticMessage{
    .message = "A '{0s}' parameter must be the first parameter.",
    .category = "Error",
    .code = "2680",
};
pub const a_constructor_cannot_have_a_this_parameter = DiagnosticMessage{
    .message = "A constructor cannot have a 'this' parameter.",
    .category = "Error",
    .code = "2681",
};
pub const this_implicitly_has_type_any_because_it_does_not_have_a_type_annotation = DiagnosticMessage{
    .message = "'this' implicitly has type 'any' because it does not have a type annotation.",
    .category = "Error",
    .code = "2683",
};
pub const the_this_context_of_type_ARG_is_not_assignable_to_method_s_this_of_type_ARG = DiagnosticMessage{
    .message = "The 'this' context of type '{0s}' is not assignable to method's 'this' of type '{1s}'.",
    .category = "Error",
    .code = "2684",
};
pub const the_this_types_of_each_signature_are_incompatible = DiagnosticMessage{
    .message = "The 'this' types of each signature are incompatible.",
    .category = "Error",
    .code = "2685",
};
pub const ARG_refers_to_a_umd_global_but_the_current_file_is_a_module_consider_adding_an_import_instead = DiagnosticMessage{
    .message = "'{0s}' refers to a UMD global, but the current file is a module. Consider adding an import instead.",
    .category = "Error",
    .code = "2686",
};
pub const all_declarations_of_ARG_must_have_identical_modifiers = DiagnosticMessage{
    .message = "All declarations of '{0s}' must have identical modifiers.",
    .category = "Error",
    .code = "2687",
};
pub const cannot_find_type_definition_file_for_ARG = DiagnosticMessage{
    .message = "Cannot find type definition file for '{0s}'.",
    .category = "Error",
    .code = "2688",
};
pub const cannot_extend_an_interface_ARG_did_you_mean_implements = DiagnosticMessage{
    .message = "Cannot extend an interface '{0s}'. Did you mean 'implements'?",
    .category = "Error",
    .code = "2689",
};
pub const ARG_only_refers_to_a_type_but_is_being_used_as_a_value_here_did_you_mean_to_use_ARG_in_ARG = DiagnosticMessage{
    .message = "'{0s}' only refers to a type, but is being used as a value here. Did you mean to use '{1s} in {0s}'?",
    .category = "Error",
    .code = "2690",
};
pub const ARG_is_a_primitive_but_ARG_is_a_wrapper_object_prefer_using_ARG_when_possible = DiagnosticMessage{
    .message = "'{0s}' is a primitive, but '{1s}' is a wrapper object. Prefer using '{0s}' when possible.",
    .category = "Error",
    .code = "2692",
};
pub const ARG_only_refers_to_a_type_but_is_being_used_as_a_value_here = DiagnosticMessage{
    .message = "'{0s}' only refers to a type, but is being used as a value here.",
    .category = "Error",
    .code = "2693",
};
pub const namespace_ARG_has_no_exported_member_ARG = DiagnosticMessage{
    .message = "Namespace '{0s}' has no exported member '{1s}'.",
    .category = "Error",
    .code = "2694",
};
pub const left_side_of_comma_operator_is_unused_and_has_no_side_effects = DiagnosticMessage{
    .message = "Left side of comma operator is unused and has no side effects.",
    .category = "Error",
    .code = "2695",
};
pub const the_object_type_is_assignable_to_very_few_other_types_did_you_mean_to_use_the_any_type_instead = DiagnosticMessage{
    .message = "The 'Object' type is assignable to very few other types. Did you mean to use the 'any' type instead?",
    .category = "Error",
    .code = "2696",
};
pub const an_async_function_or_method_must_return_a_promise_make_sure_you_have_a_declaration_for_promise_or_include_es2015_in_your_lib_option = DiagnosticMessage{
    .message = "An async function or method must return a 'Promise'. Make sure you have a declaration for 'Promise' or include 'ES2015' in your '--lib' option.",
    .category = "Error",
    .code = "2697",
};
pub const spread_types_may_only_be_created_from_object_types = DiagnosticMessage{
    .message = "Spread types may only be created from object types.",
    .category = "Error",
    .code = "2698",
};
pub const static_property_ARG_conflicts_with_built_in_property_function_ARG_of_constructor_function_ARG = DiagnosticMessage{
    .message = "Static property '{0s}' conflicts with built-in property 'Function.{0s}' of constructor function '{1s}'.",
    .category = "Error",
    .code = "2699",
};
pub const rest_types_may_only_be_created_from_object_types = DiagnosticMessage{
    .message = "Rest types may only be created from object types.",
    .category = "Error",
    .code = "2700",
};
pub const the_target_of_an_object_rest_assignment_must_be_a_variable_or_a_property_access = DiagnosticMessage{
    .message = "The target of an object rest assignment must be a variable or a property access.",
    .category = "Error",
    .code = "2701",
};
pub const ARG_only_refers_to_a_type_but_is_being_used_as_a_namespace_here = DiagnosticMessage{
    .message = "'{0s}' only refers to a type, but is being used as a namespace here.",
    .category = "Error",
    .code = "2702",
};
pub const the_operand_of_a_delete_operator_must_be_a_property_reference = DiagnosticMessage{
    .message = "The operand of a 'delete' operator must be a property reference.",
    .category = "Error",
    .code = "2703",
};
pub const the_operand_of_a_delete_operator_cannot_be_a_read_only_property = DiagnosticMessage{
    .message = "The operand of a 'delete' operator cannot be a read-only property.",
    .category = "Error",
    .code = "2704",
};
pub const an_async_function_or_method_in_es5_requires_the_promise_constructor_make_sure_you_have_a_declaration_for_the_promise_constructor_or_include_es2015_in_your_lib_option = DiagnosticMessage{
    .message = "An async function or method in ES5 requires the 'Promise' constructor.  Make sure you have a declaration for the 'Promise' constructor or include 'ES2015' in your '--lib' option.",
    .category = "Error",
    .code = "2705",
};
pub const required_type_parameters_may_not_follow_optional_type_parameters = DiagnosticMessage{
    .message = "Required type parameters may not follow optional type parameters.",
    .category = "Error",
    .code = "2706",
};
pub const generic_type_ARG_requires_between_ARG_and_ARG_type_arguments = DiagnosticMessage{
    .message = "Generic type '{0s}' requires between {1s} and {2s} type arguments.",
    .category = "Error",
    .code = "2707",
};
pub const cannot_use_namespace_ARG_as_a_value = DiagnosticMessage{
    .message = "Cannot use namespace '{0s}' as a value.",
    .category = "Error",
    .code = "2708",
};
pub const cannot_use_namespace_ARG_as_a_type = DiagnosticMessage{
    .message = "Cannot use namespace '{0s}' as a type.",
    .category = "Error",
    .code = "2709",
};
pub const ARG_are_specified_twice_the_attribute_named_ARG_will_be_overwritten = DiagnosticMessage{
    .message = "'{0s}' are specified twice. The attribute named '{0s}' will be overwritten.",
    .category = "Error",
    .code = "2710",
};
pub const a_dynamic_import_call_returns_a_promise_make_sure_you_have_a_declaration_for_promise_or_include_es2015_in_your_lib_option = DiagnosticMessage{
    .message = "A dynamic import call returns a 'Promise'. Make sure you have a declaration for 'Promise' or include 'ES2015' in your '--lib' option.",
    .category = "Error",
    .code = "2711",
};
pub const a_dynamic_import_call_in_es5_requires_the_promise_constructor_make_sure_you_have_a_declaration_for_the_promise_constructor_or_include_es2015_in_your_lib_option = DiagnosticMessage{
    .message = "A dynamic import call in ES5 requires the 'Promise' constructor.  Make sure you have a declaration for the 'Promise' constructor or include 'ES2015' in your '--lib' option.",
    .category = "Error",
    .code = "2712",
};
pub const cannot_access_ARG_ARG_because_ARG_is_a_type_but_not_a_namespace_did_you_mean_to_retrieve_the_type_of_the_property_ARG_in_ARG_with_ARG_ARG = DiagnosticMessage{
    .message = "Cannot access '{0s}.{1s}' because '{0s}' is a type, but not a namespace. Did you mean to retrieve the type of the property '{1s}' in '{0s}' with '{0s}[\"{1s}\"]'?",
    .category = "Error",
    .code = "2713",
};
pub const the_expression_of_an_export_assignment_must_be_an_identifier_or_qualified_name_in_an_ambient_context = DiagnosticMessage{
    .message = "The expression of an export assignment must be an identifier or qualified name in an ambient context.",
    .category = "Error",
    .code = "2714",
};
pub const abstract_property_ARG_in_class_ARG_cannot_be_accessed_in_the_constructor = DiagnosticMessage{
    .message = "Abstract property '{0s}' in class '{1s}' cannot be accessed in the constructor.",
    .category = "Error",
    .code = "2715",
};
pub const type_parameter_ARG_has_a_circular_default = DiagnosticMessage{
    .message = "Type parameter '{0s}' has a circular default.",
    .category = "Error",
    .code = "2716",
};
pub const subsequent_property_declarations_must_have_the_same_type_property_ARG_must_be_of_type_ARG_but_here_has_type_ARG = DiagnosticMessage{
    .message = "Subsequent property declarations must have the same type.  Property '{0s}' must be of type '{1s}', but here has type '{2s}'.",
    .category = "Error",
    .code = "2717",
};
pub const duplicate_property_ARG = DiagnosticMessage{
    .message = "Duplicate property '{0s}'.",
    .category = "Error",
    .code = "2718",
};
pub const type_ARG_is_not_assignable_to_type_ARG_two_different_types_with_this_name_exist_but_they_are_unrelated = DiagnosticMessage{
    .message = "Type '{0s}' is not assignable to type '{1s}'. Two different types with this name exist, but they are unrelated.",
    .category = "Error",
    .code = "2719",
};
pub const class_ARG_incorrectly_implements_class_ARG_did_you_mean_to_extend_ARG_and_inherit_its_members_as_a_subclass = DiagnosticMessage{
    .message = "Class '{0s}' incorrectly implements class '{1s}'. Did you mean to extend '{1s}' and inherit its members as a subclass?",
    .category = "Error",
    .code = "2720",
};
pub const cannot_invoke_an_object_which_is_possibly_null = DiagnosticMessage{
    .message = "Cannot invoke an object which is possibly 'null'.",
    .category = "Error",
    .code = "2721",
};
pub const cannot_invoke_an_object_which_is_possibly_undefined = DiagnosticMessage{
    .message = "Cannot invoke an object which is possibly 'undefined'.",
    .category = "Error",
    .code = "2722",
};
pub const cannot_invoke_an_object_which_is_possibly_null_or_undefined = DiagnosticMessage{
    .message = "Cannot invoke an object which is possibly 'null' or 'undefined'.",
    .category = "Error",
    .code = "2723",
};
pub const ARG_has_no_exported_member_named_ARG_did_you_mean_ARG = DiagnosticMessage{
    .message = "'{0s}' has no exported member named '{1s}'. Did you mean '{2s}'?",
    .category = "Error",
    .code = "2724",
};
pub const class_name_cannot_be_object_when_targeting_es5_with_module_ARG = DiagnosticMessage{
    .message = "Class name cannot be 'Object' when targeting ES5 with module {0s}.",
    .category = "Error",
    .code = "2725",
};
pub const cannot_find_lib_definition_for_ARG = DiagnosticMessage{
    .message = "Cannot find lib definition for '{0s}'.",
    .category = "Error",
    .code = "2726",
};
pub const cannot_find_lib_definition_for_ARG_did_you_mean_ARG = DiagnosticMessage{
    .message = "Cannot find lib definition for '{0s}'. Did you mean '{1s}'?",
    .category = "Error",
    .code = "2727",
};
pub const ARG_is_declared_here = DiagnosticMessage{
    .message = "'{0s}' is declared here.",
    .category = "Message",
    .code = "2728",
};
pub const property_ARG_is_used_before_its_initialization = DiagnosticMessage{
    .message = "Property '{0s}' is used before its initialization.",
    .category = "Error",
    .code = "2729",
};
pub const an_arrow_function_cannot_have_a_this_parameter = DiagnosticMessage{
    .message = "An arrow function cannot have a 'this' parameter.",
    .category = "Error",
    .code = "2730",
};
pub const implicit_conversion_of_a_symbol_to_a_string_will_fail_at_runtime_consider_wrapping_this_expression_in_string = DiagnosticMessage{
    .message = "Implicit conversion of a 'symbol' to a 'string' will fail at runtime. Consider wrapping this expression in 'String(...)'.",
    .category = "Error",
    .code = "2731",
};
pub const cannot_find_module_ARG_consider_using_resolvejsonmodule_to_import_module_with_json_extension = DiagnosticMessage{
    .message = "Cannot find module '{0s}'. Consider using '--resolveJsonModule' to import module with '.json' extension.",
    .category = "Error",
    .code = "2732",
};
pub const property_ARG_was_also_declared_here = DiagnosticMessage{
    .message = "Property '{0s}' was also declared here.",
    .category = "Error",
    .code = "2733",
};
pub const are_you_missing_a_semicolon = DiagnosticMessage{
    .message = "Are you missing a semicolon?",
    .category = "Error",
    .code = "2734",
};
pub const did_you_mean_for_ARG_to_be_constrained_to_type_new_args_any_ARG = DiagnosticMessage{
    .message = "Did you mean for '{0s}' to be constrained to type 'new (...args: any[]) => {1s}'?",
    .category = "Error",
    .code = "2735",
};
pub const operator_ARG_cannot_be_applied_to_type_ARG = DiagnosticMessage{
    .message = "Operator '{0s}' cannot be applied to type '{1s}'.",
    .category = "Error",
    .code = "2736",
};
pub const bigint_literals_are_not_available_when_targeting_lower_than_es2020 = DiagnosticMessage{
    .message = "BigInt literals are not available when targeting lower than ES2020.",
    .category = "Error",
    .code = "2737",
};
pub const an_outer_value_of_this_is_shadowed_by_this_container = DiagnosticMessage{
    .message = "An outer value of 'this' is shadowed by this container.",
    .category = "Message",
    .code = "2738",
};
pub const type_ARG_is_missing_the_following_properties_from_type_ARG_ARG = DiagnosticMessage{
    .message = "Type '{0s}' is missing the following properties from type '{1s}': {2s}",
    .category = "Error",
    .code = "2739",
};
pub const type_ARG_is_missing_the_following_properties_from_type_ARG_ARG_and_ARG_more = DiagnosticMessage{
    .message = "Type '{0s}' is missing the following properties from type '{1s}': {2s}, and {3s} more.",
    .category = "Error",
    .code = "2740",
};
pub const property_ARG_is_missing_in_type_ARG_but_required_in_type_ARG = DiagnosticMessage{
    .message = "Property '{0s}' is missing in type '{1s}' but required in type '{2s}'.",
    .category = "Error",
    .code = "2741",
};
pub const the_inferred_type_of_ARG_cannot_be_named_without_a_reference_to_ARG_this_is_likely_not_portable_a_type_annotation_is_necessary = DiagnosticMessage{
    .message = "The inferred type of '{0s}' cannot be named without a reference to '{1s}'. This is likely not portable. A type annotation is necessary.",
    .category = "Error",
    .code = "2742",
};
pub const no_overload_expects_ARG_type_arguments_but_overloads_do_exist_that_expect_either_ARG_or_ARG_type_arguments = DiagnosticMessage{
    .message = "No overload expects {0s} type arguments, but overloads do exist that expect either {1s} or {2s} type arguments.",
    .category = "Error",
    .code = "2743",
};
pub const type_parameter_defaults_can_only_reference_previously_declared_type_parameters = DiagnosticMessage{
    .message = "Type parameter defaults can only reference previously declared type parameters.",
    .category = "Error",
    .code = "2744",
};
pub const this_jsx_tag_s_ARG_prop_expects_type_ARG_which_requires_multiple_children_but_only_a_single_child_was_provided = DiagnosticMessage{
    .message = "This JSX tag's '{0s}' prop expects type '{1s}' which requires multiple children, but only a single child was provided.",
    .category = "Error",
    .code = "2745",
};
pub const this_jsx_tag_s_ARG_prop_expects_a_single_child_of_type_ARG_but_multiple_children_were_provided = DiagnosticMessage{
    .message = "This JSX tag's '{0s}' prop expects a single child of type '{1s}', but multiple children were provided.",
    .category = "Error",
    .code = "2746",
};
pub const ARG_components_don_t_accept_text_as_child_elements_text_in_jsx_has_the_type_string_but_the_expected_type_of_ARG_is_ARG = DiagnosticMessage{
    .message = "'{0s}' components don't accept text as child elements. Text in JSX has the type 'string', but the expected type of '{1s}' is '{2s}'.",
    .category = "Error",
    .code = "2747",
};
pub const cannot_access_ambient_const_enums_when_ARG_is_enabled = DiagnosticMessage{
    .message = "Cannot access ambient const enums when '{0s}' is enabled.",
    .category = "Error",
    .code = "2748",
};
pub const ARG_refers_to_a_value_but_is_being_used_as_a_type_here_did_you_mean_typeof_ARG = DiagnosticMessage{
    .message = "'{0s}' refers to a value, but is being used as a type here. Did you mean 'typeof {0s}'?",
    .category = "Error",
    .code = "2749",
};
pub const the_implementation_signature_is_declared_here = DiagnosticMessage{
    .message = "The implementation signature is declared here.",
    .category = "Error",
    .code = "2750",
};
pub const circularity_originates_in_type_at_this_location = DiagnosticMessage{
    .message = "Circularity originates in type at this location.",
    .category = "Error",
    .code = "2751",
};
pub const the_first_export_default_is_here = DiagnosticMessage{
    .message = "The first export default is here.",
    .category = "Error",
    .code = "2752",
};
pub const another_export_default_is_here = DiagnosticMessage{
    .message = "Another export default is here.",
    .category = "Error",
    .code = "2753",
};
pub const super_may_not_use_type_arguments = DiagnosticMessage{
    .message = "'super' may not use type arguments.",
    .category = "Error",
    .code = "2754",
};
pub const no_constituent_of_type_ARG_is_callable = DiagnosticMessage{
    .message = "No constituent of type '{0s}' is callable.",
    .category = "Error",
    .code = "2755",
};
pub const not_all_constituents_of_type_ARG_are_callable = DiagnosticMessage{
    .message = "Not all constituents of type '{0s}' are callable.",
    .category = "Error",
    .code = "2756",
};
pub const type_ARG_has_no_call_signatures = DiagnosticMessage{
    .message = "Type '{0s}' has no call signatures.",
    .category = "Error",
    .code = "2757",
};
pub const each_member_of_the_union_type_ARG_has_signatures_but_none_of_those_signatures_are_compatible_with_each_other = DiagnosticMessage{
    .message = "Each member of the union type '{0s}' has signatures, but none of those signatures are compatible with each other.",
    .category = "Error",
    .code = "2758",
};
pub const no_constituent_of_type_ARG_is_constructable = DiagnosticMessage{
    .message = "No constituent of type '{0s}' is constructable.",
    .category = "Error",
    .code = "2759",
};
pub const not_all_constituents_of_type_ARG_are_constructable = DiagnosticMessage{
    .message = "Not all constituents of type '{0s}' are constructable.",
    .category = "Error",
    .code = "2760",
};
pub const type_ARG_has_no_construct_signatures = DiagnosticMessage{
    .message = "Type '{0s}' has no construct signatures.",
    .category = "Error",
    .code = "2761",
};
pub const each_member_of_the_union_type_ARG_has_construct_signatures_but_none_of_those_signatures_are_compatible_with_each_other = DiagnosticMessage{
    .message = "Each member of the union type '{0s}' has construct signatures, but none of those signatures are compatible with each other.",
    .category = "Error",
    .code = "2762",
};
pub const cannot_iterate_value_because_the_next_method_of_its_iterator_expects_type_ARG_but_for_of_will_always_send_ARG = DiagnosticMessage{
    .message = "Cannot iterate value because the 'next' method of its iterator expects type '{1s}', but for-of will always send '{0s}'.",
    .category = "Error",
    .code = "2763",
};
pub const cannot_iterate_value_because_the_next_method_of_its_iterator_expects_type_ARG_but_array_spread_will_always_send_ARG = DiagnosticMessage{
    .message = "Cannot iterate value because the 'next' method of its iterator expects type '{1s}', but array spread will always send '{0s}'.",
    .category = "Error",
    .code = "2764",
};
pub const cannot_iterate_value_because_the_next_method_of_its_iterator_expects_type_ARG_but_array_destructuring_will_always_send_ARG = DiagnosticMessage{
    .message = "Cannot iterate value because the 'next' method of its iterator expects type '{1s}', but array destructuring will always send '{0s}'.",
    .category = "Error",
    .code = "2765",
};
pub const cannot_delegate_iteration_to_value_because_the_next_method_of_its_iterator_expects_type_ARG_but_the_containing_generator_will_always_send_ARG = DiagnosticMessage{
    .message = "Cannot delegate iteration to value because the 'next' method of its iterator expects type '{1s}', but the containing generator will always send '{0s}'.",
    .category = "Error",
    .code = "2766",
};
pub const the_ARG_property_of_an_iterator_must_be_a_method = DiagnosticMessage{
    .message = "The '{0s}' property of an iterator must be a method.",
    .category = "Error",
    .code = "2767",
};
pub const the_ARG_property_of_an_async_iterator_must_be_a_method = DiagnosticMessage{
    .message = "The '{0s}' property of an async iterator must be a method.",
    .category = "Error",
    .code = "2768",
};
pub const no_overload_matches_this_call = DiagnosticMessage{
    .message = "No overload matches this call.",
    .category = "Error",
    .code = "2769",
};
pub const the_last_overload_gave_the_following_error = DiagnosticMessage{
    .message = "The last overload gave the following error.",
    .category = "Error",
    .code = "2770",
};
pub const the_last_overload_is_declared_here = DiagnosticMessage{
    .message = "The last overload is declared here.",
    .category = "Error",
    .code = "2771",
};
pub const overload_ARG_of_ARG_ARG_gave_the_following_error = DiagnosticMessage{
    .message = "Overload {0s} of {1s}, '{2s}', gave the following error.",
    .category = "Error",
    .code = "2772",
};
pub const did_you_forget_to_use_await = DiagnosticMessage{
    .message = "Did you forget to use 'await'?",
    .category = "Error",
    .code = "2773",
};
pub const this_condition_will_always_return_true_since_this_function_is_always_defined_did_you_mean_to_call_it_instead = DiagnosticMessage{
    .message = "This condition will always return true since this function is always defined. Did you mean to call it instead?",
    .category = "Error",
    .code = "2774",
};
pub const assertions_require_every_name_in_the_call_target_to_be_declared_with_an_explicit_type_annotation = DiagnosticMessage{
    .message = "Assertions require every name in the call target to be declared with an explicit type annotation.",
    .category = "Error",
    .code = "2775",
};
pub const assertions_require_the_call_target_to_be_an_identifier_or_qualified_name = DiagnosticMessage{
    .message = "Assertions require the call target to be an identifier or qualified name.",
    .category = "Error",
    .code = "2776",
};
pub const the_operand_of_an_increment_or_decrement_operator_may_not_be_an_optional_property_access = DiagnosticMessage{
    .message = "The operand of an increment or decrement operator may not be an optional property access.",
    .category = "Error",
    .code = "2777",
};
pub const the_target_of_an_object_rest_assignment_may_not_be_an_optional_property_access = DiagnosticMessage{
    .message = "The target of an object rest assignment may not be an optional property access.",
    .category = "Error",
    .code = "2778",
};
pub const the_left_hand_side_of_an_assignment_expression_may_not_be_an_optional_property_access = DiagnosticMessage{
    .message = "The left-hand side of an assignment expression may not be an optional property access.",
    .category = "Error",
    .code = "2779",
};
pub const the_left_hand_side_of_a_for_in_statement_may_not_be_an_optional_property_access = DiagnosticMessage{
    .message = "The left-hand side of a 'for...in' statement may not be an optional property access.",
    .category = "Error",
    .code = "2780",
};
pub const the_left_hand_side_of_a_for_of_statement_may_not_be_an_optional_property_access = DiagnosticMessage{
    .message = "The left-hand side of a 'for...of' statement may not be an optional property access.",
    .category = "Error",
    .code = "2781",
};
pub const ARG_needs_an_explicit_type_annotation = DiagnosticMessage{
    .message = "'{0s}' needs an explicit type annotation.",
    .category = "Message",
    .code = "2782",
};
pub const ARG_is_specified_more_than_once_so_this_usage_will_be_overwritten = DiagnosticMessage{
    .message = "'{0s}' is specified more than once, so this usage will be overwritten.",
    .category = "Error",
    .code = "2783",
};
pub const get_and_set_accessors_cannot_declare_this_parameters = DiagnosticMessage{
    .message = "'get' and 'set' accessors cannot declare 'this' parameters.",
    .category = "Error",
    .code = "2784",
};
pub const this_spread_always_overwrites_this_property = DiagnosticMessage{
    .message = "This spread always overwrites this property.",
    .category = "Error",
    .code = "2785",
};
pub const ARG_cannot_be_used_as_a_jsx_component = DiagnosticMessage{
    .message = "'{0s}' cannot be used as a JSX component.",
    .category = "Error",
    .code = "2786",
};
pub const its_return_type_ARG_is_not_a_valid_jsx_element = DiagnosticMessage{
    .message = "Its return type '{0s}' is not a valid JSX element.",
    .category = "Error",
    .code = "2787",
};
pub const its_instance_type_ARG_is_not_a_valid_jsx_element = DiagnosticMessage{
    .message = "Its instance type '{0s}' is not a valid JSX element.",
    .category = "Error",
    .code = "2788",
};
pub const its_element_type_ARG_is_not_a_valid_jsx_element = DiagnosticMessage{
    .message = "Its element type '{0s}' is not a valid JSX element.",
    .category = "Error",
    .code = "2789",
};
pub const the_operand_of_a_delete_operator_must_be_optional = DiagnosticMessage{
    .message = "The operand of a 'delete' operator must be optional.",
    .category = "Error",
    .code = "2790",
};
pub const exponentiation_cannot_be_performed_on_bigint_values_unless_the_target_option_is_set_to_es2016_or_later = DiagnosticMessage{
    .message = "Exponentiation cannot be performed on 'bigint' values unless the 'target' option is set to 'es2016' or later.",
    .category = "Error",
    .code = "2791",
};
pub const cannot_find_module_ARG_did_you_mean_to_set_the_moduleresolution_option_to_nodenext_or_to_add_aliases_to_the_paths_option = DiagnosticMessage{
    .message = "Cannot find module '{0s}'. Did you mean to set the 'moduleResolution' option to 'nodenext', or to add aliases to the 'paths' option?",
    .category = "Error",
    .code = "2792",
};
pub const the_call_would_have_succeeded_against_this_implementation_but_implementation_signatures_of_overloads_are_not_externally_visible = DiagnosticMessage{
    .message = "The call would have succeeded against this implementation, but implementation signatures of overloads are not externally visible.",
    .category = "Error",
    .code = "2793",
};
pub const expected_ARG_arguments_but_got_ARG_did_you_forget_to_include_void_in_your_type_argument_to_promise = DiagnosticMessage{
    .message = "Expected {0s} arguments, but got {1s}. Did you forget to include 'void' in your type argument to 'Promise'?",
    .category = "Error",
    .code = "2794",
};
pub const the_intrinsic_keyword_can_only_be_used_to_declare_compiler_provided_intrinsic_types = DiagnosticMessage{
    .message = "The 'intrinsic' keyword can only be used to declare compiler provided intrinsic types.",
    .category = "Error",
    .code = "2795",
};
pub const it_is_likely_that_you_are_missing_a_comma_to_separate_these_two_template_expressions_they_form_a_tagged_template_expression_which_cannot_be_invoked = DiagnosticMessage{
    .message = "It is likely that you are missing a comma to separate these two template expressions. They form a tagged template expression which cannot be invoked.",
    .category = "Error",
    .code = "2796",
};
pub const a_mixin_class_that_extends_from_a_type_variable_containing_an_abstract_construct_signature_must_also_be_declared_abstract = DiagnosticMessage{
    .message = "A mixin class that extends from a type variable containing an abstract construct signature must also be declared 'abstract'.",
    .category = "Error",
    .code = "2797",
};
pub const the_declaration_was_marked_as_deprecated_here = DiagnosticMessage{
    .message = "The declaration was marked as deprecated here.",
    .category = "Error",
    .code = "2798",
};
pub const type_produces_a_tuple_type_that_is_too_large_to_represent = DiagnosticMessage{
    .message = "Type produces a tuple type that is too large to represent.",
    .category = "Error",
    .code = "2799",
};
pub const expression_produces_a_tuple_type_that_is_too_large_to_represent = DiagnosticMessage{
    .message = "Expression produces a tuple type that is too large to represent.",
    .category = "Error",
    .code = "2800",
};
pub const this_condition_will_always_return_true_since_this_ARG_is_always_defined = DiagnosticMessage{
    .message = "This condition will always return true since this '{0s}' is always defined.",
    .category = "Error",
    .code = "2801",
};
pub const type_ARG_can_only_be_iterated_through_when_using_the_downleveliteration_flag_or_with_a_target_of_es2015_or_higher = DiagnosticMessage{
    .message = "Type '{0s}' can only be iterated through when using the '--downlevelIteration' flag or with a '--target' of 'es2015' or higher.",
    .category = "Error",
    .code = "2802",
};
pub const cannot_assign_to_private_method_ARG_private_methods_are_not_writable = DiagnosticMessage{
    .message = "Cannot assign to private method '{0s}'. Private methods are not writable.",
    .category = "Error",
    .code = "2803",
};
pub const duplicate_identifier_ARG_static_and_instance_elements_cannot_share_the_same_private_name = DiagnosticMessage{
    .message = "Duplicate identifier '{0s}'. Static and instance elements cannot share the same private name.",
    .category = "Error",
    .code = "2804",
};
pub const private_accessor_was_defined_without_a_getter = DiagnosticMessage{
    .message = "Private accessor was defined without a getter.",
    .category = "Error",
    .code = "2806",
};
pub const this_syntax_requires_an_imported_helper_named_ARG_with_ARG_parameters_which_is_not_compatible_with_the_one_in_ARG_consider_upgrading_your_version_of_ARG = DiagnosticMessage{
    .message = "This syntax requires an imported helper named '{1s}' with {2s} parameters, which is not compatible with the one in '{0s}'. Consider upgrading your version of '{0s}'.",
    .category = "Error",
    .code = "2807",
};
pub const a_get_accessor_must_be_at_least_as_accessible_as_the_setter = DiagnosticMessage{
    .message = "A get accessor must be at least as accessible as the setter",
    .category = "Error",
    .code = "2808",
};
pub const declaration_or_statement_expected_this_follows_a_block_of_statements_so_if_you_intended_to_write_a_destructuring_assignment_you_might_need_to_wrap_the_whole_assignment_in_parentheses = DiagnosticMessage{
    .message = "Declaration or statement expected. This '=' follows a block of statements, so if you intended to write a destructuring assignment, you might need to wrap the whole assignment in parentheses.",
    .category = "Error",
    .code = "2809",
};
pub const expected_1_argument_but_got_0_new_promise_needs_a_jsdoc_hint_to_produce_a_resolve_that_can_be_called_without_arguments = DiagnosticMessage{
    .message = "Expected 1 argument, but got 0. 'new Promise()' needs a JSDoc hint to produce a 'resolve' that can be called without arguments.",
    .category = "Error",
    .code = "2810",
};
pub const initializer_for_property_ARG = DiagnosticMessage{
    .message = "Initializer for property '{0s}'",
    .category = "Error",
    .code = "2811",
};
pub const property_ARG_does_not_exist_on_type_ARG_try_changing_the_lib_compiler_option_to_include_dom = DiagnosticMessage{
    .message = "Property '{0s}' does not exist on type '{1s}'. Try changing the 'lib' compiler option to include 'dom'.",
    .category = "Error",
    .code = "2812",
};
pub const class_declaration_cannot_implement_overload_list_for_ARG = DiagnosticMessage{
    .message = "Class declaration cannot implement overload list for '{0s}'.",
    .category = "Error",
    .code = "2813",
};
pub const function_with_bodies_can_only_merge_with_classes_that_are_ambient = DiagnosticMessage{
    .message = "Function with bodies can only merge with classes that are ambient.",
    .category = "Error",
    .code = "2814",
};
pub const arguments_cannot_be_referenced_in_property_initializers = DiagnosticMessage{
    .message = "'arguments' cannot be referenced in property initializers.",
    .category = "Error",
    .code = "2815",
};
pub const cannot_use_this_in_a_static_property_initializer_of_a_decorated_class = DiagnosticMessage{
    .message = "Cannot use 'this' in a static property initializer of a decorated class.",
    .category = "Error",
    .code = "2816",
};
pub const property_ARG_has_no_initializer_and_is_not_definitely_assigned_in_a_class_static_block = DiagnosticMessage{
    .message = "Property '{0s}' has no initializer and is not definitely assigned in a class static block.",
    .category = "Error",
    .code = "2817",
};
pub const duplicate_identifier_ARG_compiler_reserves_name_ARG_when_emitting_super_references_in_static_initializers = DiagnosticMessage{
    .message = "Duplicate identifier '{0s}'. Compiler reserves name '{1s}' when emitting 'super' references in static initializers.",
    .category = "Error",
    .code = "2818",
};
pub const namespace_name_cannot_be_ARG = DiagnosticMessage{
    .message = "Namespace name cannot be '{0s}'.",
    .category = "Error",
    .code = "2819",
};
pub const type_ARG_is_not_assignable_to_type_ARG_did_you_mean_ARG = DiagnosticMessage{
    .message = "Type '{0s}' is not assignable to type '{1s}'. Did you mean '{2s}'?",
    .category = "Error",
    .code = "2820",
};
pub const import_assertions_are_only_supported_when_the_module_option_is_set_to_esnext_nodenext_or_preserve = DiagnosticMessage{
    .message = "Import assertions are only supported when the '--module' option is set to 'esnext', 'nodenext', or 'preserve'.",
    .category = "Error",
    .code = "2821",
};
pub const import_assertions_cannot_be_used_with_type_only_imports_or_exports = DiagnosticMessage{
    .message = "Import assertions cannot be used with type-only imports or exports.",
    .category = "Error",
    .code = "2822",
};
pub const import_attributes_are_only_supported_when_the_module_option_is_set_to_esnext_nodenext_or_preserve = DiagnosticMessage{
    .message = "Import attributes are only supported when the '--module' option is set to 'esnext', 'nodenext', or 'preserve'.",
    .category = "Error",
    .code = "2823",
};
pub const cannot_find_namespace_ARG_did_you_mean_ARG = DiagnosticMessage{
    .message = "Cannot find namespace '{0s}'. Did you mean '{1s}'?",
    .category = "Error",
    .code = "2833",
};
pub const relative_import_paths_need_explicit_file_extensions_in_ecmascript_imports_when_moduleresolution_is_node16_or_nodenext_consider_adding_an_extension_to_the_import_path = DiagnosticMessage{
    .message = "Relative import paths need explicit file extensions in ECMAScript imports when '--moduleResolution' is 'node16' or 'nodenext'. Consider adding an extension to the import path.",
    .category = "Error",
    .code = "2834",
};
pub const relative_import_paths_need_explicit_file_extensions_in_ecmascript_imports_when_moduleresolution_is_node16_or_nodenext_did_you_mean_ARG = DiagnosticMessage{
    .message = "Relative import paths need explicit file extensions in ECMAScript imports when '--moduleResolution' is 'node16' or 'nodenext'. Did you mean '{0s}'?",
    .category = "Error",
    .code = "2835",
};
pub const import_assertions_are_not_allowed_on_statements_that_compile_to_commonjs_require_calls = DiagnosticMessage{
    .message = "Import assertions are not allowed on statements that compile to CommonJS 'require' calls.",
    .category = "Error",
    .code = "2836",
};
pub const import_assertion_values_must_be_string_literal_expressions = DiagnosticMessage{
    .message = "Import assertion values must be string literal expressions.",
    .category = "Error",
    .code = "2837",
};
pub const all_declarations_of_ARG_must_have_identical_constraints = DiagnosticMessage{
    .message = "All declarations of '{0s}' must have identical constraints.",
    .category = "Error",
    .code = "2838",
};
pub const this_condition_will_always_return_ARG_since_javascript_compares_objects_by_reference_not_value = DiagnosticMessage{
    .message = "This condition will always return '{0s}' since JavaScript compares objects by reference, not value.",
    .category = "Error",
    .code = "2839",
};
pub const an_interface_cannot_extend_a_primitive_type_like_ARG_it_can_only_extend_other_named_object_types = DiagnosticMessage{
    .message = "An interface cannot extend a primitive type like '{0s}'. It can only extend other named object types.",
    .category = "Error",
    .code = "2840",
};
pub const ARG_is_an_unused_renaming_of_ARG_did_you_intend_to_use_it_as_a_type_annotation = DiagnosticMessage{
    .message = "'{0s}' is an unused renaming of '{1s}'. Did you intend to use it as a type annotation?",
    .category = "Error",
    .code = "2842",
};
pub const we_can_only_write_a_type_for_ARG_by_adding_a_type_for_the_entire_parameter_here = DiagnosticMessage{
    .message = "We can only write a type for '{0s}' by adding a type for the entire parameter here.",
    .category = "Error",
    .code = "2843",
};
pub const type_of_instance_member_variable_ARG_cannot_reference_identifier_ARG_declared_in_the_constructor = DiagnosticMessage{
    .message = "Type of instance member variable '{0s}' cannot reference identifier '{1s}' declared in the constructor.",
    .category = "Error",
    .code = "2844",
};
pub const this_condition_will_always_return_ARG = DiagnosticMessage{
    .message = "This condition will always return '{0s}'.",
    .category = "Error",
    .code = "2845",
};
pub const a_declaration_file_cannot_be_imported_without_import_type_did_you_mean_to_import_an_implementation_file_ARG_instead = DiagnosticMessage{
    .message = "A declaration file cannot be imported without 'import type'. Did you mean to import an implementation file '{0s}' instead?",
    .category = "Error",
    .code = "2846",
};
pub const the_right_hand_side_of_an_instanceof_expression_must_not_be_an_instantiation_expression = DiagnosticMessage{
    .message = "The right-hand side of an 'instanceof' expression must not be an instantiation expression.",
    .category = "Error",
    .code = "2848",
};
pub const target_signature_provides_too_few_arguments_expected_ARG_or_more_but_got_ARG = DiagnosticMessage{
    .message = "Target signature provides too few arguments. Expected {0s} or more, but got {1s}.",
    .category = "Error",
    .code = "2849",
};
pub const the_initializer_of_a_using_declaration_must_be_either_an_object_with_a_symbol_dispose_method_or_be_null_or_undefined = DiagnosticMessage{
    .message = "The initializer of a 'using' declaration must be either an object with a '[Symbol.dispose]()' method, or be 'null' or 'undefined'.",
    .category = "Error",
    .code = "2850",
};
pub const the_initializer_of_an_await_using_declaration_must_be_either_an_object_with_a_symbol_asyncdispose_or_symbol_dispose_method_or_be_null_or_undefined = DiagnosticMessage{
    .message = "The initializer of an 'await using' declaration must be either an object with a '[Symbol.asyncDispose]()' or '[Symbol.dispose]()' method, or be 'null' or 'undefined'.",
    .category = "Error",
    .code = "2851",
};
pub const await_using_statements_are_only_allowed_within_async_functions_and_at_the_top_levels_of_modules = DiagnosticMessage{
    .message = "'await using' statements are only allowed within async functions and at the top levels of modules.",
    .category = "Error",
    .code = "2852",
};
pub const await_using_statements_are_only_allowed_at_the_top_level_of_a_file_when_that_file_is_a_module_but_this_file_has_no_imports_or_exports_consider_adding_an_empty_export_ARG_to_make_this_file_a_module = DiagnosticMessage{
    .message = "'await using' statements are only allowed at the top level of a file when that file is a module, but this file has no imports or exports. Consider adding an empty 'export {{}' to make this file a module.",
    .category = "Error",
    .code = "2853",
};
pub const top_level_await_using_statements_are_only_allowed_when_the_module_option_is_set_to_es2022_esnext_system_node16_nodenext_or_preserve_and_the_target_option_is_set_to_es2017_or_higher = DiagnosticMessage{
    .message = "Top-level 'await using' statements are only allowed when the 'module' option is set to 'es2022', 'esnext', 'system', 'node16', 'nodenext', or 'preserve', and the 'target' option is set to 'es2017' or higher.",
    .category = "Error",
    .code = "2854",
};
pub const class_field_ARG_defined_by_the_parent_class_is_not_accessible_in_the_child_class_via_super = DiagnosticMessage{
    .message = "Class field '{0s}' defined by the parent class is not accessible in the child class via super.",
    .category = "Error",
    .code = "2855",
};
pub const import_attributes_are_not_allowed_on_statements_that_compile_to_commonjs_require_calls = DiagnosticMessage{
    .message = "Import attributes are not allowed on statements that compile to CommonJS 'require' calls.",
    .category = "Error",
    .code = "2856",
};
pub const import_attributes_cannot_be_used_with_type_only_imports_or_exports = DiagnosticMessage{
    .message = "Import attributes cannot be used with type-only imports or exports.",
    .category = "Error",
    .code = "2857",
};
pub const import_attribute_values_must_be_string_literal_expressions = DiagnosticMessage{
    .message = "Import attribute values must be string literal expressions.",
    .category = "Error",
    .code = "2858",
};
pub const excessive_complexity_comparing_types_ARG_and_ARG = DiagnosticMessage{
    .message = "Excessive complexity comparing types '{0s}' and '{1s}'.",
    .category = "Error",
    .code = "2859",
};
pub const the_left_hand_side_of_an_instanceof_expression_must_be_assignable_to_the_first_argument_of_the_right_hand_side_s_symbol_hasinstance_method = DiagnosticMessage{
    .message = "The left-hand side of an 'instanceof' expression must be assignable to the first argument of the right-hand side's '[Symbol.hasInstance]' method.",
    .category = "Error",
    .code = "2860",
};
pub const an_object_s_symbol_hasinstance_method_must_return_a_boolean_value_for_it_to_be_used_on_the_right_hand_side_of_an_instanceof_expression = DiagnosticMessage{
    .message = "An object's '[Symbol.hasInstance]' method must return a boolean value for it to be used on the right-hand side of an 'instanceof' expression.",
    .category = "Error",
    .code = "2861",
};
pub const type_ARG_is_generic_and_can_only_be_indexed_for_reading = DiagnosticMessage{
    .message = "Type '{0s}' is generic and can only be indexed for reading.",
    .category = "Error",
    .code = "2862",
};
pub const a_class_cannot_extend_a_primitive_type_like_ARG_classes_can_only_extend_constructable_values = DiagnosticMessage{
    .message = "A class cannot extend a primitive type like '{0s}'. Classes can only extend constructable values.",
    .category = "Error",
    .code = "2863",
};
pub const a_class_cannot_implement_a_primitive_type_like_ARG_it_can_only_implement_other_named_object_types = DiagnosticMessage{
    .message = "A class cannot implement a primitive type like '{0s}'. It can only implement other named object types.",
    .category = "Error",
    .code = "2864",
};
pub const import_ARG_conflicts_with_local_value_so_must_be_declared_with_a_type_only_import_when_isolatedmodules_is_enabled = DiagnosticMessage{
    .message = "Import '{0s}' conflicts with local value, so must be declared with a type-only import when 'isolatedModules' is enabled.",
    .category = "Error",
    .code = "2865",
};
pub const import_ARG_conflicts_with_global_value_used_in_this_file_so_must_be_declared_with_a_type_only_import_when_isolatedmodules_is_enabled = DiagnosticMessage{
    .message = "Import '{0s}' conflicts with global value used in this file, so must be declared with a type-only import when 'isolatedModules' is enabled.",
    .category = "Error",
    .code = "2866",
};
pub const cannot_find_name_ARG_do_you_need_to_install_type_definitions_for_bun_try_npm_i_save_dev_types_bun = DiagnosticMessage{
    .message = "Cannot find name '{0s}'. Do you need to install type definitions for Bun? Try `npm i --save-dev @types/bun`.",
    .category = "Error",
    .code = "2867",
};
pub const cannot_find_name_ARG_do_you_need_to_install_type_definitions_for_bun_try_npm_i_save_dev_types_bun_and_then_add_bun_to_the_types_field_in_your_tsconfig = DiagnosticMessage{
    .message = "Cannot find name '{0s}'. Do you need to install type definitions for Bun? Try `npm i --save-dev @types/bun` and then add 'bun' to the types field in your tsconfig.",
    .category = "Error",
    .code = "2868",
};
pub const import_declaration_ARG_is_using_private_name_ARG = DiagnosticMessage{
    .message = "Import declaration '{0s}' is using private name '{1s}'.",
    .category = "Error",
    .code = "4000",
};
pub const type_parameter_ARG_of_exported_class_has_or_is_using_private_name_ARG = DiagnosticMessage{
    .message = "Type parameter '{0s}' of exported class has or is using private name '{1s}'.",
    .category = "Error",
    .code = "4002",
};
pub const type_parameter_ARG_of_exported_interface_has_or_is_using_private_name_ARG = DiagnosticMessage{
    .message = "Type parameter '{0s}' of exported interface has or is using private name '{1s}'.",
    .category = "Error",
    .code = "4004",
};
pub const type_parameter_ARG_of_constructor_signature_from_exported_interface_has_or_is_using_private_name_ARG = DiagnosticMessage{
    .message = "Type parameter '{0s}' of constructor signature from exported interface has or is using private name '{1s}'.",
    .category = "Error",
    .code = "4006",
};
pub const type_parameter_ARG_of_call_signature_from_exported_interface_has_or_is_using_private_name_ARG = DiagnosticMessage{
    .message = "Type parameter '{0s}' of call signature from exported interface has or is using private name '{1s}'.",
    .category = "Error",
    .code = "4008",
};
pub const type_parameter_ARG_of_public_static_method_from_exported_class_has_or_is_using_private_name_ARG = DiagnosticMessage{
    .message = "Type parameter '{0s}' of public static method from exported class has or is using private name '{1s}'.",
    .category = "Error",
    .code = "4010",
};
pub const type_parameter_ARG_of_public_method_from_exported_class_has_or_is_using_private_name_ARG = DiagnosticMessage{
    .message = "Type parameter '{0s}' of public method from exported class has or is using private name '{1s}'.",
    .category = "Error",
    .code = "4012",
};
pub const type_parameter_ARG_of_method_from_exported_interface_has_or_is_using_private_name_ARG = DiagnosticMessage{
    .message = "Type parameter '{0s}' of method from exported interface has or is using private name '{1s}'.",
    .category = "Error",
    .code = "4014",
};
pub const type_parameter_ARG_of_exported_function_has_or_is_using_private_name_ARG = DiagnosticMessage{
    .message = "Type parameter '{0s}' of exported function has or is using private name '{1s}'.",
    .category = "Error",
    .code = "4016",
};
pub const implements_clause_of_exported_class_ARG_has_or_is_using_private_name_ARG = DiagnosticMessage{
    .message = "Implements clause of exported class '{0s}' has or is using private name '{1s}'.",
    .category = "Error",
    .code = "4019",
};
pub const extends_clause_of_exported_class_ARG_has_or_is_using_private_name_ARG = DiagnosticMessage{
    .message = "'extends' clause of exported class '{0s}' has or is using private name '{1s}'.",
    .category = "Error",
    .code = "4020",
};
pub const extends_clause_of_exported_class_has_or_is_using_private_name_ARG = DiagnosticMessage{
    .message = "'extends' clause of exported class has or is using private name '{0s}'.",
    .category = "Error",
    .code = "4021",
};
pub const extends_clause_of_exported_interface_ARG_has_or_is_using_private_name_ARG = DiagnosticMessage{
    .message = "'extends' clause of exported interface '{0s}' has or is using private name '{1s}'.",
    .category = "Error",
    .code = "4022",
};
pub const exported_variable_ARG_has_or_is_using_name_ARG_from_external_module_ARG_but_cannot_be_named = DiagnosticMessage{
    .message = "Exported variable '{0s}' has or is using name '{1s}' from external module {2s} but cannot be named.",
    .category = "Error",
    .code = "4023",
};
pub const exported_variable_ARG_has_or_is_using_name_ARG_from_private_module_ARG = DiagnosticMessage{
    .message = "Exported variable '{0s}' has or is using name '{1s}' from private module '{2s}'.",
    .category = "Error",
    .code = "4024",
};
pub const exported_variable_ARG_has_or_is_using_private_name_ARG = DiagnosticMessage{
    .message = "Exported variable '{0s}' has or is using private name '{1s}'.",
    .category = "Error",
    .code = "4025",
};
pub const public_static_property_ARG_of_exported_class_has_or_is_using_name_ARG_from_external_module_ARG_but_cannot_be_named = DiagnosticMessage{
    .message = "Public static property '{0s}' of exported class has or is using name '{1s}' from external module {2s} but cannot be named.",
    .category = "Error",
    .code = "4026",
};
pub const public_static_property_ARG_of_exported_class_has_or_is_using_name_ARG_from_private_module_ARG = DiagnosticMessage{
    .message = "Public static property '{0s}' of exported class has or is using name '{1s}' from private module '{2s}'.",
    .category = "Error",
    .code = "4027",
};
pub const public_static_property_ARG_of_exported_class_has_or_is_using_private_name_ARG = DiagnosticMessage{
    .message = "Public static property '{0s}' of exported class has or is using private name '{1s}'.",
    .category = "Error",
    .code = "4028",
};
pub const public_property_ARG_of_exported_class_has_or_is_using_name_ARG_from_external_module_ARG_but_cannot_be_named = DiagnosticMessage{
    .message = "Public property '{0s}' of exported class has or is using name '{1s}' from external module {2s} but cannot be named.",
    .category = "Error",
    .code = "4029",
};
pub const public_property_ARG_of_exported_class_has_or_is_using_name_ARG_from_private_module_ARG = DiagnosticMessage{
    .message = "Public property '{0s}' of exported class has or is using name '{1s}' from private module '{2s}'.",
    .category = "Error",
    .code = "4030",
};
pub const public_property_ARG_of_exported_class_has_or_is_using_private_name_ARG = DiagnosticMessage{
    .message = "Public property '{0s}' of exported class has or is using private name '{1s}'.",
    .category = "Error",
    .code = "4031",
};
pub const property_ARG_of_exported_interface_has_or_is_using_name_ARG_from_private_module_ARG = DiagnosticMessage{
    .message = "Property '{0s}' of exported interface has or is using name '{1s}' from private module '{2s}'.",
    .category = "Error",
    .code = "4032",
};
pub const property_ARG_of_exported_interface_has_or_is_using_private_name_ARG = DiagnosticMessage{
    .message = "Property '{0s}' of exported interface has or is using private name '{1s}'.",
    .category = "Error",
    .code = "4033",
};
pub const parameter_type_of_public_static_setter_ARG_from_exported_class_has_or_is_using_name_ARG_from_private_module_ARG = DiagnosticMessage{
    .message = "Parameter type of public static setter '{0s}' from exported class has or is using name '{1s}' from private module '{2s}'.",
    .category = "Error",
    .code = "4034",
};
pub const parameter_type_of_public_static_setter_ARG_from_exported_class_has_or_is_using_private_name_ARG = DiagnosticMessage{
    .message = "Parameter type of public static setter '{0s}' from exported class has or is using private name '{1s}'.",
    .category = "Error",
    .code = "4035",
};
pub const parameter_type_of_public_setter_ARG_from_exported_class_has_or_is_using_name_ARG_from_private_module_ARG = DiagnosticMessage{
    .message = "Parameter type of public setter '{0s}' from exported class has or is using name '{1s}' from private module '{2s}'.",
    .category = "Error",
    .code = "4036",
};
pub const parameter_type_of_public_setter_ARG_from_exported_class_has_or_is_using_private_name_ARG = DiagnosticMessage{
    .message = "Parameter type of public setter '{0s}' from exported class has or is using private name '{1s}'.",
    .category = "Error",
    .code = "4037",
};
pub const return_type_of_public_static_getter_ARG_from_exported_class_has_or_is_using_name_ARG_from_external_module_ARG_but_cannot_be_named = DiagnosticMessage{
    .message = "Return type of public static getter '{0s}' from exported class has or is using name '{1s}' from external module {2s} but cannot be named.",
    .category = "Error",
    .code = "4038",
};
pub const return_type_of_public_static_getter_ARG_from_exported_class_has_or_is_using_name_ARG_from_private_module_ARG = DiagnosticMessage{
    .message = "Return type of public static getter '{0s}' from exported class has or is using name '{1s}' from private module '{2s}'.",
    .category = "Error",
    .code = "4039",
};
pub const return_type_of_public_static_getter_ARG_from_exported_class_has_or_is_using_private_name_ARG = DiagnosticMessage{
    .message = "Return type of public static getter '{0s}' from exported class has or is using private name '{1s}'.",
    .category = "Error",
    .code = "4040",
};
pub const return_type_of_public_getter_ARG_from_exported_class_has_or_is_using_name_ARG_from_external_module_ARG_but_cannot_be_named = DiagnosticMessage{
    .message = "Return type of public getter '{0s}' from exported class has or is using name '{1s}' from external module {2s} but cannot be named.",
    .category = "Error",
    .code = "4041",
};
pub const return_type_of_public_getter_ARG_from_exported_class_has_or_is_using_name_ARG_from_private_module_ARG = DiagnosticMessage{
    .message = "Return type of public getter '{0s}' from exported class has or is using name '{1s}' from private module '{2s}'.",
    .category = "Error",
    .code = "4042",
};
pub const return_type_of_public_getter_ARG_from_exported_class_has_or_is_using_private_name_ARG = DiagnosticMessage{
    .message = "Return type of public getter '{0s}' from exported class has or is using private name '{1s}'.",
    .category = "Error",
    .code = "4043",
};
pub const return_type_of_constructor_signature_from_exported_interface_has_or_is_using_name_ARG_from_private_module_ARG = DiagnosticMessage{
    .message = "Return type of constructor signature from exported interface has or is using name '{0s}' from private module '{1s}'.",
    .category = "Error",
    .code = "4044",
};
pub const return_type_of_constructor_signature_from_exported_interface_has_or_is_using_private_name_ARG = DiagnosticMessage{
    .message = "Return type of constructor signature from exported interface has or is using private name '{0s}'.",
    .category = "Error",
    .code = "4045",
};
pub const return_type_of_call_signature_from_exported_interface_has_or_is_using_name_ARG_from_private_module_ARG = DiagnosticMessage{
    .message = "Return type of call signature from exported interface has or is using name '{0s}' from private module '{1s}'.",
    .category = "Error",
    .code = "4046",
};
pub const return_type_of_call_signature_from_exported_interface_has_or_is_using_private_name_ARG = DiagnosticMessage{
    .message = "Return type of call signature from exported interface has or is using private name '{0s}'.",
    .category = "Error",
    .code = "4047",
};
pub const return_type_of_index_signature_from_exported_interface_has_or_is_using_name_ARG_from_private_module_ARG = DiagnosticMessage{
    .message = "Return type of index signature from exported interface has or is using name '{0s}' from private module '{1s}'.",
    .category = "Error",
    .code = "4048",
};
pub const return_type_of_index_signature_from_exported_interface_has_or_is_using_private_name_ARG = DiagnosticMessage{
    .message = "Return type of index signature from exported interface has or is using private name '{0s}'.",
    .category = "Error",
    .code = "4049",
};
pub const return_type_of_public_static_method_from_exported_class_has_or_is_using_name_ARG_from_external_module_ARG_but_cannot_be_named = DiagnosticMessage{
    .message = "Return type of public static method from exported class has or is using name '{0s}' from external module {1s} but cannot be named.",
    .category = "Error",
    .code = "4050",
};
pub const return_type_of_public_static_method_from_exported_class_has_or_is_using_name_ARG_from_private_module_ARG = DiagnosticMessage{
    .message = "Return type of public static method from exported class has or is using name '{0s}' from private module '{1s}'.",
    .category = "Error",
    .code = "4051",
};
pub const return_type_of_public_static_method_from_exported_class_has_or_is_using_private_name_ARG = DiagnosticMessage{
    .message = "Return type of public static method from exported class has or is using private name '{0s}'.",
    .category = "Error",
    .code = "4052",
};
pub const return_type_of_public_method_from_exported_class_has_or_is_using_name_ARG_from_external_module_ARG_but_cannot_be_named = DiagnosticMessage{
    .message = "Return type of public method from exported class has or is using name '{0s}' from external module {1s} but cannot be named.",
    .category = "Error",
    .code = "4053",
};
pub const return_type_of_public_method_from_exported_class_has_or_is_using_name_ARG_from_private_module_ARG = DiagnosticMessage{
    .message = "Return type of public method from exported class has or is using name '{0s}' from private module '{1s}'.",
    .category = "Error",
    .code = "4054",
};
pub const return_type_of_public_method_from_exported_class_has_or_is_using_private_name_ARG = DiagnosticMessage{
    .message = "Return type of public method from exported class has or is using private name '{0s}'.",
    .category = "Error",
    .code = "4055",
};
pub const return_type_of_method_from_exported_interface_has_or_is_using_name_ARG_from_private_module_ARG = DiagnosticMessage{
    .message = "Return type of method from exported interface has or is using name '{0s}' from private module '{1s}'.",
    .category = "Error",
    .code = "4056",
};
pub const return_type_of_method_from_exported_interface_has_or_is_using_private_name_ARG = DiagnosticMessage{
    .message = "Return type of method from exported interface has or is using private name '{0s}'.",
    .category = "Error",
    .code = "4057",
};
pub const return_type_of_exported_function_has_or_is_using_name_ARG_from_external_module_ARG_but_cannot_be_named = DiagnosticMessage{
    .message = "Return type of exported function has or is using name '{0s}' from external module {1s} but cannot be named.",
    .category = "Error",
    .code = "4058",
};
pub const return_type_of_exported_function_has_or_is_using_name_ARG_from_private_module_ARG = DiagnosticMessage{
    .message = "Return type of exported function has or is using name '{0s}' from private module '{1s}'.",
    .category = "Error",
    .code = "4059",
};
pub const return_type_of_exported_function_has_or_is_using_private_name_ARG = DiagnosticMessage{
    .message = "Return type of exported function has or is using private name '{0s}'.",
    .category = "Error",
    .code = "4060",
};
pub const parameter_ARG_of_constructor_from_exported_class_has_or_is_using_name_ARG_from_external_module_ARG_but_cannot_be_named = DiagnosticMessage{
    .message = "Parameter '{0s}' of constructor from exported class has or is using name '{1s}' from external module {2s} but cannot be named.",
    .category = "Error",
    .code = "4061",
};
pub const parameter_ARG_of_constructor_from_exported_class_has_or_is_using_name_ARG_from_private_module_ARG = DiagnosticMessage{
    .message = "Parameter '{0s}' of constructor from exported class has or is using name '{1s}' from private module '{2s}'.",
    .category = "Error",
    .code = "4062",
};
pub const parameter_ARG_of_constructor_from_exported_class_has_or_is_using_private_name_ARG = DiagnosticMessage{
    .message = "Parameter '{0s}' of constructor from exported class has or is using private name '{1s}'.",
    .category = "Error",
    .code = "4063",
};
pub const parameter_ARG_of_constructor_signature_from_exported_interface_has_or_is_using_name_ARG_from_private_module_ARG = DiagnosticMessage{
    .message = "Parameter '{0s}' of constructor signature from exported interface has or is using name '{1s}' from private module '{2s}'.",
    .category = "Error",
    .code = "4064",
};
pub const parameter_ARG_of_constructor_signature_from_exported_interface_has_or_is_using_private_name_ARG = DiagnosticMessage{
    .message = "Parameter '{0s}' of constructor signature from exported interface has or is using private name '{1s}'.",
    .category = "Error",
    .code = "4065",
};
pub const parameter_ARG_of_call_signature_from_exported_interface_has_or_is_using_name_ARG_from_private_module_ARG = DiagnosticMessage{
    .message = "Parameter '{0s}' of call signature from exported interface has or is using name '{1s}' from private module '{2s}'.",
    .category = "Error",
    .code = "4066",
};
pub const parameter_ARG_of_call_signature_from_exported_interface_has_or_is_using_private_name_ARG = DiagnosticMessage{
    .message = "Parameter '{0s}' of call signature from exported interface has or is using private name '{1s}'.",
    .category = "Error",
    .code = "4067",
};
pub const parameter_ARG_of_public_static_method_from_exported_class_has_or_is_using_name_ARG_from_external_module_ARG_but_cannot_be_named = DiagnosticMessage{
    .message = "Parameter '{0s}' of public static method from exported class has or is using name '{1s}' from external module {2s} but cannot be named.",
    .category = "Error",
    .code = "4068",
};
pub const parameter_ARG_of_public_static_method_from_exported_class_has_or_is_using_name_ARG_from_private_module_ARG = DiagnosticMessage{
    .message = "Parameter '{0s}' of public static method from exported class has or is using name '{1s}' from private module '{2s}'.",
    .category = "Error",
    .code = "4069",
};
pub const parameter_ARG_of_public_static_method_from_exported_class_has_or_is_using_private_name_ARG = DiagnosticMessage{
    .message = "Parameter '{0s}' of public static method from exported class has or is using private name '{1s}'.",
    .category = "Error",
    .code = "4070",
};
pub const parameter_ARG_of_public_method_from_exported_class_has_or_is_using_name_ARG_from_external_module_ARG_but_cannot_be_named = DiagnosticMessage{
    .message = "Parameter '{0s}' of public method from exported class has or is using name '{1s}' from external module {2s} but cannot be named.",
    .category = "Error",
    .code = "4071",
};
pub const parameter_ARG_of_public_method_from_exported_class_has_or_is_using_name_ARG_from_private_module_ARG = DiagnosticMessage{
    .message = "Parameter '{0s}' of public method from exported class has or is using name '{1s}' from private module '{2s}'.",
    .category = "Error",
    .code = "4072",
};
pub const parameter_ARG_of_public_method_from_exported_class_has_or_is_using_private_name_ARG = DiagnosticMessage{
    .message = "Parameter '{0s}' of public method from exported class has or is using private name '{1s}'.",
    .category = "Error",
    .code = "4073",
};
pub const parameter_ARG_of_method_from_exported_interface_has_or_is_using_name_ARG_from_private_module_ARG = DiagnosticMessage{
    .message = "Parameter '{0s}' of method from exported interface has or is using name '{1s}' from private module '{2s}'.",
    .category = "Error",
    .code = "4074",
};
pub const parameter_ARG_of_method_from_exported_interface_has_or_is_using_private_name_ARG = DiagnosticMessage{
    .message = "Parameter '{0s}' of method from exported interface has or is using private name '{1s}'.",
    .category = "Error",
    .code = "4075",
};
pub const parameter_ARG_of_exported_function_has_or_is_using_name_ARG_from_external_module_ARG_but_cannot_be_named = DiagnosticMessage{
    .message = "Parameter '{0s}' of exported function has or is using name '{1s}' from external module {2s} but cannot be named.",
    .category = "Error",
    .code = "4076",
};
pub const parameter_ARG_of_exported_function_has_or_is_using_name_ARG_from_private_module_ARG = DiagnosticMessage{
    .message = "Parameter '{0s}' of exported function has or is using name '{1s}' from private module '{2s}'.",
    .category = "Error",
    .code = "4077",
};
pub const parameter_ARG_of_exported_function_has_or_is_using_private_name_ARG = DiagnosticMessage{
    .message = "Parameter '{0s}' of exported function has or is using private name '{1s}'.",
    .category = "Error",
    .code = "4078",
};
pub const exported_type_alias_ARG_has_or_is_using_private_name_ARG = DiagnosticMessage{
    .message = "Exported type alias '{0s}' has or is using private name '{1s}'.",
    .category = "Error",
    .code = "4081",
};
pub const default_export_of_the_module_has_or_is_using_private_name_ARG = DiagnosticMessage{
    .message = "Default export of the module has or is using private name '{0s}'.",
    .category = "Error",
    .code = "4082",
};
pub const type_parameter_ARG_of_exported_type_alias_has_or_is_using_private_name_ARG = DiagnosticMessage{
    .message = "Type parameter '{0s}' of exported type alias has or is using private name '{1s}'.",
    .category = "Error",
    .code = "4083",
};
pub const exported_type_alias_ARG_has_or_is_using_private_name_ARG_from_module_ARG = DiagnosticMessage{
    .message = "Exported type alias '{0s}' has or is using private name '{1s}' from module {2s}.",
    .category = "Error",
    .code = "4084",
};
pub const extends_clause_for_inferred_type_ARG_has_or_is_using_private_name_ARG = DiagnosticMessage{
    .message = "Extends clause for inferred type '{0s}' has or is using private name '{1s}'.",
    .category = "Error",
    .code = "4085",
};
pub const parameter_ARG_of_index_signature_from_exported_interface_has_or_is_using_name_ARG_from_private_module_ARG = DiagnosticMessage{
    .message = "Parameter '{0s}' of index signature from exported interface has or is using name '{1s}' from private module '{2s}'.",
    .category = "Error",
    .code = "4091",
};
pub const parameter_ARG_of_index_signature_from_exported_interface_has_or_is_using_private_name_ARG = DiagnosticMessage{
    .message = "Parameter '{0s}' of index signature from exported interface has or is using private name '{1s}'.",
    .category = "Error",
    .code = "4092",
};
pub const property_ARG_of_exported_class_expression_may_not_be_private_or_protected = DiagnosticMessage{
    .message = "Property '{0s}' of exported class expression may not be private or protected.",
    .category = "Error",
    .code = "4094",
};
pub const public_static_method_ARG_of_exported_class_has_or_is_using_name_ARG_from_external_module_ARG_but_cannot_be_named = DiagnosticMessage{
    .message = "Public static method '{0s}' of exported class has or is using name '{1s}' from external module {2s} but cannot be named.",
    .category = "Error",
    .code = "4095",
};
pub const public_static_method_ARG_of_exported_class_has_or_is_using_name_ARG_from_private_module_ARG = DiagnosticMessage{
    .message = "Public static method '{0s}' of exported class has or is using name '{1s}' from private module '{2s}'.",
    .category = "Error",
    .code = "4096",
};
pub const public_static_method_ARG_of_exported_class_has_or_is_using_private_name_ARG = DiagnosticMessage{
    .message = "Public static method '{0s}' of exported class has or is using private name '{1s}'.",
    .category = "Error",
    .code = "4097",
};
pub const public_method_ARG_of_exported_class_has_or_is_using_name_ARG_from_external_module_ARG_but_cannot_be_named = DiagnosticMessage{
    .message = "Public method '{0s}' of exported class has or is using name '{1s}' from external module {2s} but cannot be named.",
    .category = "Error",
    .code = "4098",
};
pub const public_method_ARG_of_exported_class_has_or_is_using_name_ARG_from_private_module_ARG = DiagnosticMessage{
    .message = "Public method '{0s}' of exported class has or is using name '{1s}' from private module '{2s}'.",
    .category = "Error",
    .code = "4099",
};
pub const public_method_ARG_of_exported_class_has_or_is_using_private_name_ARG = DiagnosticMessage{
    .message = "Public method '{0s}' of exported class has or is using private name '{1s}'.",
    .category = "Error",
    .code = "4100",
};
pub const method_ARG_of_exported_interface_has_or_is_using_name_ARG_from_private_module_ARG = DiagnosticMessage{
    .message = "Method '{0s}' of exported interface has or is using name '{1s}' from private module '{2s}'.",
    .category = "Error",
    .code = "4101",
};
pub const method_ARG_of_exported_interface_has_or_is_using_private_name_ARG = DiagnosticMessage{
    .message = "Method '{0s}' of exported interface has or is using private name '{1s}'.",
    .category = "Error",
    .code = "4102",
};
pub const type_parameter_ARG_of_exported_mapped_object_type_is_using_private_name_ARG = DiagnosticMessage{
    .message = "Type parameter '{0s}' of exported mapped object type is using private name '{1s}'.",
    .category = "Error",
    .code = "4103",
};
pub const the_type_ARG_is_readonly_and_cannot_be_assigned_to_the_mutable_type_ARG = DiagnosticMessage{
    .message = "The type '{0s}' is 'readonly' and cannot be assigned to the mutable type '{1s}'.",
    .category = "Error",
    .code = "4104",
};
pub const private_or_protected_member_ARG_cannot_be_accessed_on_a_type_parameter = DiagnosticMessage{
    .message = "Private or protected member '{0s}' cannot be accessed on a type parameter.",
    .category = "Error",
    .code = "4105",
};
pub const parameter_ARG_of_accessor_has_or_is_using_private_name_ARG = DiagnosticMessage{
    .message = "Parameter '{0s}' of accessor has or is using private name '{1s}'.",
    .category = "Error",
    .code = "4106",
};
pub const parameter_ARG_of_accessor_has_or_is_using_name_ARG_from_private_module_ARG = DiagnosticMessage{
    .message = "Parameter '{0s}' of accessor has or is using name '{1s}' from private module '{2s}'.",
    .category = "Error",
    .code = "4107",
};
pub const parameter_ARG_of_accessor_has_or_is_using_name_ARG_from_external_module_ARG_but_cannot_be_named = DiagnosticMessage{
    .message = "Parameter '{0s}' of accessor has or is using name '{1s}' from external module '{2s}' but cannot be named.",
    .category = "Error",
    .code = "4108",
};
pub const type_arguments_for_ARG_circularly_reference_themselves = DiagnosticMessage{
    .message = "Type arguments for '{0s}' circularly reference themselves.",
    .category = "Error",
    .code = "4109",
};
pub const tuple_type_arguments_circularly_reference_themselves = DiagnosticMessage{
    .message = "Tuple type arguments circularly reference themselves.",
    .category = "Error",
    .code = "4110",
};
pub const property_ARG_comes_from_an_index_signature_so_it_must_be_accessed_with_ARG = DiagnosticMessage{
    .message = "Property '{0s}' comes from an index signature, so it must be accessed with ['{0s}'].",
    .category = "Error",
    .code = "4111",
};
pub const this_member_cannot_have_an_override_modifier_because_its_containing_class_ARG_does_not_extend_another_class = DiagnosticMessage{
    .message = "This member cannot have an 'override' modifier because its containing class '{0s}' does not extend another class.",
    .category = "Error",
    .code = "4112",
};
pub const this_member_cannot_have_an_override_modifier_because_it_is_not_declared_in_the_base_class_ARG = DiagnosticMessage{
    .message = "This member cannot have an 'override' modifier because it is not declared in the base class '{0s}'.",
    .category = "Error",
    .code = "4113",
};
pub const this_member_must_have_an_override_modifier_because_it_overrides_a_member_in_the_base_class_ARG = DiagnosticMessage{
    .message = "This member must have an 'override' modifier because it overrides a member in the base class '{0s}'.",
    .category = "Error",
    .code = "4114",
};
pub const this_parameter_property_must_have_an_override_modifier_because_it_overrides_a_member_in_base_class_ARG = DiagnosticMessage{
    .message = "This parameter property must have an 'override' modifier because it overrides a member in base class '{0s}'.",
    .category = "Error",
    .code = "4115",
};
pub const this_member_must_have_an_override_modifier_because_it_overrides_an_abstract_method_that_is_declared_in_the_base_class_ARG = DiagnosticMessage{
    .message = "This member must have an 'override' modifier because it overrides an abstract method that is declared in the base class '{0s}'.",
    .category = "Error",
    .code = "4116",
};
pub const this_member_cannot_have_an_override_modifier_because_it_is_not_declared_in_the_base_class_ARG_did_you_mean_ARG = DiagnosticMessage{
    .message = "This member cannot have an 'override' modifier because it is not declared in the base class '{0s}'. Did you mean '{1s}'?",
    .category = "Error",
    .code = "4117",
};
pub const the_type_of_this_node_cannot_be_serialized_because_its_property_ARG_cannot_be_serialized = DiagnosticMessage{
    .message = "The type of this node cannot be serialized because its property '{0s}' cannot be serialized.",
    .category = "Error",
    .code = "4118",
};
pub const this_member_must_have_a_jsdoc_comment_with_an_override_tag_because_it_overrides_a_member_in_the_base_class_ARG = DiagnosticMessage{
    .message = "This member must have a JSDoc comment with an '@override' tag because it overrides a member in the base class '{0s}'.",
    .category = "Error",
    .code = "4119",
};
pub const this_parameter_property_must_have_a_jsdoc_comment_with_an_override_tag_because_it_overrides_a_member_in_the_base_class_ARG = DiagnosticMessage{
    .message = "This parameter property must have a JSDoc comment with an '@override' tag because it overrides a member in the base class '{0s}'.",
    .category = "Error",
    .code = "4120",
};
pub const this_member_cannot_have_a_jsdoc_comment_with_an_override_tag_because_its_containing_class_ARG_does_not_extend_another_class = DiagnosticMessage{
    .message = "This member cannot have a JSDoc comment with an '@override' tag because its containing class '{0s}' does not extend another class.",
    .category = "Error",
    .code = "4121",
};
pub const this_member_cannot_have_a_jsdoc_comment_with_an_override_tag_because_it_is_not_declared_in_the_base_class_ARG = DiagnosticMessage{
    .message = "This member cannot have a JSDoc comment with an '@override' tag because it is not declared in the base class '{0s}'.",
    .category = "Error",
    .code = "4122",
};
pub const this_member_cannot_have_a_jsdoc_comment_with_an_override_tag_because_it_is_not_declared_in_the_base_class_ARG_did_you_mean_ARG = DiagnosticMessage{
    .message = "This member cannot have a JSDoc comment with an 'override' tag because it is not declared in the base class '{0s}'. Did you mean '{1s}'?",
    .category = "Error",
    .code = "4123",
};
pub const compiler_option_ARG_of_value_ARG_is_unstable_use_nightly_typescript_to_silence_this_error_try_updating_with_npm_install_d_typescript_next = DiagnosticMessage{
    .message = "Compiler option '{0s}' of value '{1s}' is unstable. Use nightly TypeScript to silence this error. Try updating with 'npm install -D typescript@next'.",
    .category = "Error",
    .code = "4124",
};
pub const each_declaration_of_ARG_ARG_differs_in_its_value_where_ARG_was_expected_but_ARG_was_given = DiagnosticMessage{
    .message = "Each declaration of '{0s}.{1s}' differs in its value, where '{2s}' was expected but '{3s}' was given.",
    .category = "Error",
    .code = "4125",
};
pub const one_value_of_ARG_ARG_is_the_string_ARG_and_the_other_is_assumed_to_be_an_unknown_numeric_value = DiagnosticMessage{
    .message = "One value of '{0s}.{1s}' is the string '{2s}', and the other is assumed to be an unknown numeric value.",
    .category = "Error",
    .code = "4126",
};
pub const the_current_host_does_not_support_the_ARG_option = DiagnosticMessage{
    .message = "The current host does not support the '{0s}' option.",
    .category = "Error",
    .code = "5001",
};
pub const cannot_find_the_common_subdirectory_path_for_the_input_files = DiagnosticMessage{
    .message = "Cannot find the common subdirectory path for the input files.",
    .category = "Error",
    .code = "5009",
};
pub const file_specification_cannot_end_in_a_recursive_directory_wildcard_ARG = DiagnosticMessage{
    .message = "File specification cannot end in a recursive directory wildcard ('**'): '{0s}'.",
    .category = "Error",
    .code = "5010",
};
pub const cannot_read_file_ARG_ARG = DiagnosticMessage{
    .message = "Cannot read file '{0s}': {1s}.",
    .category = "Error",
    .code = "5012",
};
pub const failed_to_parse_file_ARG_ARG = DiagnosticMessage{
    .message = "Failed to parse file '{0s}': {1s}.",
    .category = "Error",
    .code = "5014",
};
pub const unknown_compiler_option_ARG = DiagnosticMessage{
    .message = "Unknown compiler option '{0s}'.",
    .category = "Error",
    .code = "5023",
};
pub const compiler_option_ARG_requires_a_value_of_type_ARG = DiagnosticMessage{
    .message = "Compiler option '{0s}' requires a value of type {1s}.",
    .category = "Error",
    .code = "5024",
};
pub const unknown_compiler_option_ARG_did_you_mean_ARG = DiagnosticMessage{
    .message = "Unknown compiler option '{0s}'. Did you mean '{1s}'?",
    .category = "Error",
    .code = "5025",
};
pub const could_not_write_file_ARG_ARG = DiagnosticMessage{
    .message = "Could not write file '{0s}': {1s}.",
    .category = "Error",
    .code = "5033",
};
pub const option_project_cannot_be_mixed_with_source_files_on_a_command_line = DiagnosticMessage{
    .message = "Option 'project' cannot be mixed with source files on a command line.",
    .category = "Error",
    .code = "5042",
};
pub const option_isolatedmodules_can_only_be_used_when_either_option_module_is_provided_or_option_target_is_es2015_or_higher = DiagnosticMessage{
    .message = "Option 'isolatedModules' can only be used when either option '--module' is provided or option 'target' is 'ES2015' or higher.",
    .category = "Error",
    .code = "5047",
};
pub const option_ARG_can_only_be_used_when_either_option_inlinesourcemap_or_option_sourcemap_is_provided = DiagnosticMessage{
    .message = "Option '{0s} can only be used when either option '--inlineSourceMap' or option '--sourceMap' is provided.",
    .category = "Error",
    .code = "5051",
};
pub const option_ARG_cannot_be_specified_without_specifying_option_ARG = DiagnosticMessage{
    .message = "Option '{0s}' cannot be specified without specifying option '{1s}'.",
    .category = "Error",
    .code = "5052",
};
pub const option_ARG_cannot_be_specified_with_option_ARG = DiagnosticMessage{
    .message = "Option '{0s}' cannot be specified with option '{1s}'.",
    .category = "Error",
    .code = "5053",
};
pub const a_tsconfig_json_file_is_already_defined_at_ARG = DiagnosticMessage{
    .message = "A 'tsconfig.json' file is already defined at: '{0s}'.",
    .category = "Error",
    .code = "5054",
};
pub const cannot_write_file_ARG_because_it_would_overwrite_input_file = DiagnosticMessage{
    .message = "Cannot write file '{0s}' because it would overwrite input file.",
    .category = "Error",
    .code = "5055",
};
pub const cannot_write_file_ARG_because_it_would_be_overwritten_by_multiple_input_files = DiagnosticMessage{
    .message = "Cannot write file '{0s}' because it would be overwritten by multiple input files.",
    .category = "Error",
    .code = "5056",
};
pub const cannot_find_a_tsconfig_json_file_at_the_specified_directory_ARG = DiagnosticMessage{
    .message = "Cannot find a tsconfig.json file at the specified directory: '{0s}'.",
    .category = "Error",
    .code = "5057",
};
pub const the_specified_path_does_not_exist_ARG = DiagnosticMessage{
    .message = "The specified path does not exist: '{0s}'.",
    .category = "Error",
    .code = "5058",
};
pub const invalid_value_for_reactnamespace_ARG_is_not_a_valid_identifier = DiagnosticMessage{
    .message = "Invalid value for '--reactNamespace'. '{0s}' is not a valid identifier.",
    .category = "Error",
    .code = "5059",
};
pub const pattern_ARG_can_have_at_most_one_character = DiagnosticMessage{
    .message = "Pattern '{0s}' can have at most one '*' character.",
    .category = "Error",
    .code = "5061",
};
pub const substitution_ARG_in_pattern_ARG_can_have_at_most_one_character = DiagnosticMessage{
    .message = "Substitution '{0s}' in pattern '{1s}' can have at most one '*' character.",
    .category = "Error",
    .code = "5062",
};
pub const substitutions_for_pattern_ARG_should_be_an_array = DiagnosticMessage{
    .message = "Substitutions for pattern '{0s}' should be an array.",
    .category = "Error",
    .code = "5063",
};
pub const substitution_ARG_for_pattern_ARG_has_incorrect_type_expected_string_got_ARG = DiagnosticMessage{
    .message = "Substitution '{0s}' for pattern '{1s}' has incorrect type, expected 'string', got '{2s}'.",
    .category = "Error",
    .code = "5064",
};
pub const file_specification_cannot_contain_a_parent_directory_that_appears_after_a_recursive_directory_wildcard_ARG = DiagnosticMessage{
    .message = "File specification cannot contain a parent directory ('..') that appears after a recursive directory wildcard ('**'): '{0s}'.",
    .category = "Error",
    .code = "5065",
};
pub const substitutions_for_pattern_ARG_shouldn_t_be_an_empty_array = DiagnosticMessage{
    .message = "Substitutions for pattern '{0s}' shouldn't be an empty array.",
    .category = "Error",
    .code = "5066",
};
pub const invalid_value_for_jsxfactory_ARG_is_not_a_valid_identifier_or_qualified_name = DiagnosticMessage{
    .message = "Invalid value for 'jsxFactory'. '{0s}' is not a valid identifier or qualified-name.",
    .category = "Error",
    .code = "5067",
};
pub const adding_a_tsconfig_json_file_will_help_organize_projects_that_contain_both_typescript_and_javascript_files_learn_more_at_https_aka_ms_tsconfig = DiagnosticMessage{
    .message = "Adding a tsconfig.json file will help organize projects that contain both TypeScript and JavaScript files. Learn more at https://aka.ms/tsconfig.",
    .category = "Error",
    .code = "5068",
};
pub const option_ARG_cannot_be_specified_without_specifying_option_ARG_or_option_ARG = DiagnosticMessage{
    .message = "Option '{0s}' cannot be specified without specifying option '{1s}' or option '{2s}'.",
    .category = "Error",
    .code = "5069",
};
pub const option_resolvejsonmodule_cannot_be_specified_when_moduleresolution_is_set_to_classic = DiagnosticMessage{
    .message = "Option '--resolveJsonModule' cannot be specified when 'moduleResolution' is set to 'classic'.",
    .category = "Error",
    .code = "5070",
};
pub const option_resolvejsonmodule_cannot_be_specified_when_module_is_set_to_none_system_or_umd = DiagnosticMessage{
    .message = "Option '--resolveJsonModule' cannot be specified when 'module' is set to 'none', 'system', or 'umd'.",
    .category = "Error",
    .code = "5071",
};
pub const unknown_build_option_ARG = DiagnosticMessage{
    .message = "Unknown build option '{0s}'.",
    .category = "Error",
    .code = "5072",
};
pub const build_option_ARG_requires_a_value_of_type_ARG = DiagnosticMessage{
    .message = "Build option '{0s}' requires a value of type {1s}.",
    .category = "Error",
    .code = "5073",
};
pub const option_incremental_can_only_be_specified_using_tsconfig_emitting_to_single_file_or_when_option_tsbuildinfofile_is_specified = DiagnosticMessage{
    .message = "Option '--incremental' can only be specified using tsconfig, emitting to single file or when option '--tsBuildInfoFile' is specified.",
    .category = "Error",
    .code = "5074",
};
pub const ARG_is_assignable_to_the_constraint_of_type_ARG_but_ARG_could_be_instantiated_with_a_different_subtype_of_constraint_ARG = DiagnosticMessage{
    .message = "'{0s}' is assignable to the constraint of type '{1s}', but '{1s}' could be instantiated with a different subtype of constraint '{2s}'.",
    .category = "Error",
    .code = "5075",
};
pub const ARG_and_ARG_operations_cannot_be_mixed_without_parentheses = DiagnosticMessage{
    .message = "'{0s}' and '{1s}' operations cannot be mixed without parentheses.",
    .category = "Error",
    .code = "5076",
};
pub const unknown_build_option_ARG_did_you_mean_ARG = DiagnosticMessage{
    .message = "Unknown build option '{0s}'. Did you mean '{1s}'?",
    .category = "Error",
    .code = "5077",
};
pub const unknown_watch_option_ARG = DiagnosticMessage{
    .message = "Unknown watch option '{0s}'.",
    .category = "Error",
    .code = "5078",
};
pub const unknown_watch_option_ARG_did_you_mean_ARG = DiagnosticMessage{
    .message = "Unknown watch option '{0s}'. Did you mean '{1s}'?",
    .category = "Error",
    .code = "5079",
};
pub const watch_option_ARG_requires_a_value_of_type_ARG = DiagnosticMessage{
    .message = "Watch option '{0s}' requires a value of type {1s}.",
    .category = "Error",
    .code = "5080",
};
pub const cannot_find_a_tsconfig_json_file_at_the_current_directory_ARG = DiagnosticMessage{
    .message = "Cannot find a tsconfig.json file at the current directory: {0s}.",
    .category = "Error",
    .code = "5081",
};
pub const ARG_could_be_instantiated_with_an_arbitrary_type_which_could_be_unrelated_to_ARG = DiagnosticMessage{
    .message = "'{0s}' could be instantiated with an arbitrary type which could be unrelated to '{1s}'.",
    .category = "Error",
    .code = "5082",
};
pub const cannot_read_file_ARG = DiagnosticMessage{
    .message = "Cannot read file '{0s}'.",
    .category = "Error",
    .code = "5083",
};
pub const a_tuple_member_cannot_be_both_optional_and_rest = DiagnosticMessage{
    .message = "A tuple member cannot be both optional and rest.",
    .category = "Error",
    .code = "5085",
};
pub const a_labeled_tuple_element_is_declared_as_optional_with_a_question_mark_after_the_name_and_before_the_colon_rather_than_after_the_type = DiagnosticMessage{
    .message = "A labeled tuple element is declared as optional with a question mark after the name and before the colon, rather than after the type.",
    .category = "Error",
    .code = "5086",
};
pub const a_labeled_tuple_element_is_declared_as_rest_with_a_before_the_name_rather_than_before_the_type = DiagnosticMessage{
    .message = "A labeled tuple element is declared as rest with a '...' before the name, rather than before the type.",
    .category = "Error",
    .code = "5087",
};
pub const the_inferred_type_of_ARG_references_a_type_with_a_cyclic_structure_which_cannot_be_trivially_serialized_a_type_annotation_is_necessary = DiagnosticMessage{
    .message = "The inferred type of '{0s}' references a type with a cyclic structure which cannot be trivially serialized. A type annotation is necessary.",
    .category = "Error",
    .code = "5088",
};
pub const option_ARG_cannot_be_specified_when_option_jsx_is_ARG = DiagnosticMessage{
    .message = "Option '{0s}' cannot be specified when option 'jsx' is '{1s}'.",
    .category = "Error",
    .code = "5089",
};
pub const non_relative_paths_are_not_allowed_when_baseurl_is_not_set_did_you_forget_a_leading = DiagnosticMessage{
    .message = "Non-relative paths are not allowed when 'baseUrl' is not set. Did you forget a leading './'?",
    .category = "Error",
    .code = "5090",
};
pub const option_preserveconstenums_cannot_be_disabled_when_ARG_is_enabled = DiagnosticMessage{
    .message = "Option 'preserveConstEnums' cannot be disabled when '{0s}' is enabled.",
    .category = "Error",
    .code = "5091",
};
pub const the_root_value_of_a_ARG_file_must_be_an_object = DiagnosticMessage{
    .message = "The root value of a '{0s}' file must be an object.",
    .category = "Error",
    .code = "5092",
};
pub const compiler_option_ARG_may_only_be_used_with_build = DiagnosticMessage{
    .message = "Compiler option '--{0s}' may only be used with '--build'.",
    .category = "Error",
    .code = "5093",
};
pub const compiler_option_ARG_may_not_be_used_with_build = DiagnosticMessage{
    .message = "Compiler option '--{0s}' may not be used with '--build'.",
    .category = "Error",
    .code = "5094",
};
pub const option_ARG_can_only_be_used_when_module_is_set_to_preserve_or_to_es2015_or_later = DiagnosticMessage{
    .message = "Option '{0s}' can only be used when 'module' is set to 'preserve' or to 'es2015' or later.",
    .category = "Error",
    .code = "5095",
};
pub const option_allowimportingtsextensions_can_only_be_used_when_either_noemit_or_emitdeclarationonly_is_set = DiagnosticMessage{
    .message = "Option 'allowImportingTsExtensions' can only be used when either 'noEmit' or 'emitDeclarationOnly' is set.",
    .category = "Error",
    .code = "5096",
};
pub const an_import_path_can_only_end_with_a_ARG_extension_when_allowimportingtsextensions_is_enabled = DiagnosticMessage{
    .message = "An import path can only end with a '{0s}' extension when 'allowImportingTsExtensions' is enabled.",
    .category = "Error",
    .code = "5097",
};
pub const option_ARG_can_only_be_used_when_moduleresolution_is_set_to_node16_nodenext_or_bundler = DiagnosticMessage{
    .message = "Option '{0s}' can only be used when 'moduleResolution' is set to 'node16', 'nodenext', or 'bundler'.",
    .category = "Error",
    .code = "5098",
};
pub const option_ARG_is_deprecated_and_will_stop_functioning_in_typescript_ARG_specify_compileroption_ignoredeprecations_ARG_to_silence_this_error = DiagnosticMessage{
    .message = "Option '{0s}' is deprecated and will stop functioning in TypeScript {1s}. Specify compilerOption '\"ignoreDeprecations\": \"{2s}\"' to silence this error.",
    .category = "Error",
    .code = "5101",
};
pub const option_ARG_has_been_removed_please_remove_it_from_your_configuration = DiagnosticMessage{
    .message = "Option '{0s}' has been removed. Please remove it from your configuration.",
    .category = "Error",
    .code = "5102",
};
pub const invalid_value_for_ignoredeprecations = DiagnosticMessage{
    .message = "Invalid value for '--ignoreDeprecations'.",
    .category = "Error",
    .code = "5103",
};
pub const option_ARG_is_redundant_and_cannot_be_specified_with_option_ARG = DiagnosticMessage{
    .message = "Option '{0s}' is redundant and cannot be specified with option '{1s}'.",
    .category = "Error",
    .code = "5104",
};
pub const option_verbatimmodulesyntax_cannot_be_used_when_module_is_set_to_umd_amd_or_system = DiagnosticMessage{
    .message = "Option 'verbatimModuleSyntax' cannot be used when 'module' is set to 'UMD', 'AMD', or 'System'.",
    .category = "Error",
    .code = "5105",
};
pub const use_ARG_instead = DiagnosticMessage{
    .message = "Use '{0s}' instead.",
    .category = "Message",
    .code = "5106",
};
pub const option_ARG_ARG_is_deprecated_and_will_stop_functioning_in_typescript_ARG_specify_compileroption_ignoredeprecations_ARG_to_silence_this_error = DiagnosticMessage{
    .message = "Option '{0s}={1s}' is deprecated and will stop functioning in TypeScript {2s}. Specify compilerOption '\"ignoreDeprecations\": \"{3s}\"' to silence this error.",
    .category = "Error",
    .code = "5107",
};
pub const option_ARG_ARG_has_been_removed_please_remove_it_from_your_configuration = DiagnosticMessage{
    .message = "Option '{0s}={1s}' has been removed. Please remove it from your configuration.",
    .category = "Error",
    .code = "5108",
};
pub const option_moduleresolution_must_be_set_to_ARG_or_left_unspecified_when_option_module_is_set_to_ARG = DiagnosticMessage{
    .message = "Option 'moduleResolution' must be set to '{0s}' (or left unspecified) when option 'module' is set to '{1s}'.",
    .category = "Error",
    .code = "5109",
};
pub const option_module_must_be_set_to_ARG_when_option_moduleresolution_is_set_to_ARG = DiagnosticMessage{
    .message = "Option 'module' must be set to '{0s}' when option 'moduleResolution' is set to '{1s}'.",
    .category = "Error",
    .code = "5110",
};
pub const generates_a_sourcemap_for_each_corresponding_d_ts_file = DiagnosticMessage{
    .message = "Generates a sourcemap for each corresponding '.d.ts' file.",
    .category = "Message",
    .code = "6000",
};
pub const concatenate_and_emit_output_to_single_file = DiagnosticMessage{
    .message = "Concatenate and emit output to single file.",
    .category = "Message",
    .code = "6001",
};
pub const generates_corresponding_d_ts_file = DiagnosticMessage{
    .message = "Generates corresponding '.d.ts' file.",
    .category = "Message",
    .code = "6002",
};
pub const specify_the_location_where_debugger_should_locate_typescript_files_instead_of_source_locations = DiagnosticMessage{
    .message = "Specify the location where debugger should locate TypeScript files instead of source locations.",
    .category = "Message",
    .code = "6004",
};
pub const watch_input_files = DiagnosticMessage{
    .message = "Watch input files.",
    .category = "Message",
    .code = "6005",
};
pub const redirect_output_structure_to_the_directory = DiagnosticMessage{
    .message = "Redirect output structure to the directory.",
    .category = "Message",
    .code = "6006",
};
pub const do_not_erase_const_enum_declarations_in_generated_code = DiagnosticMessage{
    .message = "Do not erase const enum declarations in generated code.",
    .category = "Message",
    .code = "6007",
};
pub const do_not_emit_outputs_if_any_errors_were_reported = DiagnosticMessage{
    .message = "Do not emit outputs if any errors were reported.",
    .category = "Message",
    .code = "6008",
};
pub const do_not_emit_comments_to_output = DiagnosticMessage{
    .message = "Do not emit comments to output.",
    .category = "Message",
    .code = "6009",
};
pub const do_not_emit_outputs = DiagnosticMessage{
    .message = "Do not emit outputs.",
    .category = "Message",
    .code = "6010",
};
pub const allow_default_imports_from_modules_with_no_default_export_this_does_not_affect_code_emit_just_typechecking = DiagnosticMessage{
    .message = "Allow default imports from modules with no default export. This does not affect code emit, just typechecking.",
    .category = "Message",
    .code = "6011",
};
pub const skip_type_checking_of_declaration_files = DiagnosticMessage{
    .message = "Skip type checking of declaration files.",
    .category = "Message",
    .code = "6012",
};
pub const do_not_resolve_the_real_path_of_symlinks = DiagnosticMessage{
    .message = "Do not resolve the real path of symlinks.",
    .category = "Message",
    .code = "6013",
};
pub const only_emit_d_ts_declaration_files = DiagnosticMessage{
    .message = "Only emit '.d.ts' declaration files.",
    .category = "Message",
    .code = "6014",
};
pub const specify_ecmascript_target_version = DiagnosticMessage{
    .message = "Specify ECMAScript target version.",
    .category = "Message",
    .code = "6015",
};
pub const specify_module_code_generation = DiagnosticMessage{
    .message = "Specify module code generation.",
    .category = "Message",
    .code = "6016",
};
pub const print_this_message = DiagnosticMessage{
    .message = "Print this message.",
    .category = "Message",
    .code = "6017",
};
pub const print_the_compiler_s_version = DiagnosticMessage{
    .message = "Print the compiler's version.",
    .category = "Message",
    .code = "6019",
};
pub const compile_the_project_given_the_path_to_its_configuration_file_or_to_a_folder_with_a_tsconfig_json = DiagnosticMessage{
    .message = "Compile the project given the path to its configuration file, or to a folder with a 'tsconfig.json'.",
    .category = "Message",
    .code = "6020",
};
pub const syntax_ARG = DiagnosticMessage{
    .message = "Syntax: {0s}",
    .category = "Message",
    .code = "6023",
};
pub const options = DiagnosticMessage{
    .message = "options",
    .category = "Message",
    .code = "6024",
};
pub const file = DiagnosticMessage{
    .message = "file",
    .category = "Message",
    .code = "6025",
};
pub const examples_ARG = DiagnosticMessage{
    .message = "Examples: {0s}",
    .category = "Message",
    .code = "6026",
};
pub const options_1 = DiagnosticMessage{
    .message = "Options:",
    .category = "Message",
    .code = "6027",
};
pub const version_ARG = DiagnosticMessage{
    .message = "Version {0s}",
    .category = "Message",
    .code = "6029",
};
pub const insert_command_line_options_and_files_from_a_file = DiagnosticMessage{
    .message = "Insert command line options and files from a file.",
    .category = "Message",
    .code = "6030",
};
pub const starting_compilation_in_watch_mode = DiagnosticMessage{
    .message = "Starting compilation in watch mode...",
    .category = "Message",
    .code = "6031",
};
pub const file_change_detected_starting_incremental_compilation = DiagnosticMessage{
    .message = "File change detected. Starting incremental compilation...",
    .category = "Message",
    .code = "6032",
};
pub const kind = DiagnosticMessage{
    .message = "KIND",
    .category = "Message",
    .code = "6034",
};
pub const file_1 = DiagnosticMessage{
    .message = "FILE",
    .category = "Message",
    .code = "6035",
};
pub const version = DiagnosticMessage{
    .message = "VERSION",
    .category = "Message",
    .code = "6036",
};
pub const location = DiagnosticMessage{
    .message = "LOCATION",
    .category = "Message",
    .code = "6037",
};
pub const directory = DiagnosticMessage{
    .message = "DIRECTORY",
    .category = "Message",
    .code = "6038",
};
pub const strategy = DiagnosticMessage{
    .message = "STRATEGY",
    .category = "Message",
    .code = "6039",
};
pub const file_or_directory = DiagnosticMessage{
    .message = "FILE OR DIRECTORY",
    .category = "Message",
    .code = "6040",
};
pub const errors_files = DiagnosticMessage{
    .message = "Errors  Files",
    .category = "Message",
    .code = "6041",
};
pub const generates_corresponding_map_file = DiagnosticMessage{
    .message = "Generates corresponding '.map' file.",
    .category = "Message",
    .code = "6043",
};
pub const compiler_option_ARG_expects_an_argument = DiagnosticMessage{
    .message = "Compiler option '{0s}' expects an argument.",
    .category = "Error",
    .code = "6044",
};
pub const unterminated_quoted_string_in_response_file_ARG = DiagnosticMessage{
    .message = "Unterminated quoted string in response file '{0s}'.",
    .category = "Error",
    .code = "6045",
};
pub const argument_for_ARG_option_must_be_ARG = DiagnosticMessage{
    .message = "Argument for '{0s}' option must be: {1s}.",
    .category = "Error",
    .code = "6046",
};
pub const locale_must_be_of_the_form_language_or_language_territory_for_example_ARG_or_ARG = DiagnosticMessage{
    .message = "Locale must be of the form <language> or <language>-<territory>. For example '{0s}' or '{1s}'.",
    .category = "Error",
    .code = "6048",
};
pub const unable_to_open_file_ARG = DiagnosticMessage{
    .message = "Unable to open file '{0s}'.",
    .category = "Error",
    .code = "6050",
};
pub const corrupted_locale_file_ARG = DiagnosticMessage{
    .message = "Corrupted locale file {0s}.",
    .category = "Error",
    .code = "6051",
};
pub const raise_error_on_expressions_and_declarations_with_an_implied_any_type = DiagnosticMessage{
    .message = "Raise error on expressions and declarations with an implied 'any' type.",
    .category = "Message",
    .code = "6052",
};
pub const file_ARG_not_found = DiagnosticMessage{
    .message = "File '{0s}' not found.",
    .category = "Error",
    .code = "6053",
};
pub const file_ARG_has_an_unsupported_extension_the_only_supported_extensions_are_ARG = DiagnosticMessage{
    .message = "File '{0s}' has an unsupported extension. The only supported extensions are {1s}.",
    .category = "Error",
    .code = "6054",
};
pub const suppress_noimplicitany_errors_for_indexing_objects_lacking_index_signatures = DiagnosticMessage{
    .message = "Suppress noImplicitAny errors for indexing objects lacking index signatures.",
    .category = "Message",
    .code = "6055",
};
pub const do_not_emit_declarations_for_code_that_has_an_internal_annotation = DiagnosticMessage{
    .message = "Do not emit declarations for code that has an '@internal' annotation.",
    .category = "Message",
    .code = "6056",
};
pub const specify_the_root_directory_of_input_files_use_to_control_the_output_directory_structure_with_outdir = DiagnosticMessage{
    .message = "Specify the root directory of input files. Use to control the output directory structure with --outDir.",
    .category = "Message",
    .code = "6058",
};
pub const file_ARG_is_not_under_rootdir_ARG_rootdir_is_expected_to_contain_all_source_files = DiagnosticMessage{
    .message = "File '{0s}' is not under 'rootDir' '{1s}'. 'rootDir' is expected to contain all source files.",
    .category = "Error",
    .code = "6059",
};
pub const specify_the_end_of_line_sequence_to_be_used_when_emitting_files_crlf_dos_or_lf_unix = DiagnosticMessage{
    .message = "Specify the end of line sequence to be used when emitting files: 'CRLF' (dos) or 'LF' (unix).",
    .category = "Message",
    .code = "6060",
};
pub const newline = DiagnosticMessage{
    .message = "NEWLINE",
    .category = "Message",
    .code = "6061",
};
pub const option_ARG_can_only_be_specified_in_tsconfig_json_file_or_set_to_null_on_command_line = DiagnosticMessage{
    .message = "Option '{0s}' can only be specified in 'tsconfig.json' file or set to 'null' on command line.",
    .category = "Error",
    .code = "6064",
};
pub const enables_experimental_support_for_es7_decorators = DiagnosticMessage{
    .message = "Enables experimental support for ES7 decorators.",
    .category = "Message",
    .code = "6065",
};
pub const enables_experimental_support_for_emitting_type_metadata_for_decorators = DiagnosticMessage{
    .message = "Enables experimental support for emitting type metadata for decorators.",
    .category = "Message",
    .code = "6066",
};
pub const initializes_a_typescript_project_and_creates_a_tsconfig_json_file = DiagnosticMessage{
    .message = "Initializes a TypeScript project and creates a tsconfig.json file.",
    .category = "Message",
    .code = "6070",
};
pub const successfully_created_a_tsconfig_json_file = DiagnosticMessage{
    .message = "Successfully created a tsconfig.json file.",
    .category = "Message",
    .code = "6071",
};
pub const suppress_excess_property_checks_for_object_literals = DiagnosticMessage{
    .message = "Suppress excess property checks for object literals.",
    .category = "Message",
    .code = "6072",
};
pub const stylize_errors_and_messages_using_color_and_context_experimental = DiagnosticMessage{
    .message = "Stylize errors and messages using color and context (experimental).",
    .category = "Message",
    .code = "6073",
};
pub const do_not_report_errors_on_unused_labels = DiagnosticMessage{
    .message = "Do not report errors on unused labels.",
    .category = "Message",
    .code = "6074",
};
pub const report_error_when_not_all_code_paths_in_function_return_a_value = DiagnosticMessage{
    .message = "Report error when not all code paths in function return a value.",
    .category = "Message",
    .code = "6075",
};
pub const report_errors_for_fallthrough_cases_in_switch_statement = DiagnosticMessage{
    .message = "Report errors for fallthrough cases in switch statement.",
    .category = "Message",
    .code = "6076",
};
pub const do_not_report_errors_on_unreachable_code = DiagnosticMessage{
    .message = "Do not report errors on unreachable code.",
    .category = "Message",
    .code = "6077",
};
pub const disallow_inconsistently_cased_references_to_the_same_file = DiagnosticMessage{
    .message = "Disallow inconsistently-cased references to the same file.",
    .category = "Message",
    .code = "6078",
};
pub const specify_library_files_to_be_included_in_the_compilation = DiagnosticMessage{
    .message = "Specify library files to be included in the compilation.",
    .category = "Message",
    .code = "6079",
};
pub const specify_jsx_code_generation = DiagnosticMessage{
    .message = "Specify JSX code generation.",
    .category = "Message",
    .code = "6080",
};
pub const only_amd_and_system_modules_are_supported_alongside_ARG = DiagnosticMessage{
    .message = "Only 'amd' and 'system' modules are supported alongside --{0s}.",
    .category = "Error",
    .code = "6082",
};
pub const base_directory_to_resolve_non_absolute_module_names = DiagnosticMessage{
    .message = "Base directory to resolve non-absolute module names.",
    .category = "Message",
    .code = "6083",
};
pub const deprecated_use_jsxfactory_instead_specify_the_object_invoked_for_createelement_when_targeting_react_jsx_emit = DiagnosticMessage{
    .message = "[Deprecated] Use '--jsxFactory' instead. Specify the object invoked for createElement when targeting 'react' JSX emit",
    .category = "Message",
    .code = "6084",
};
pub const enable_tracing_of_the_name_resolution_process = DiagnosticMessage{
    .message = "Enable tracing of the name resolution process.",
    .category = "Message",
    .code = "6085",
};
pub const resolving_module_ARG_from_ARG = DiagnosticMessage{
    .message = "======== Resolving module '{0s}' from '{1s}'. ========",
    .category = "Message",
    .code = "6086",
};
pub const explicitly_specified_module_resolution_kind_ARG = DiagnosticMessage{
    .message = "Explicitly specified module resolution kind: '{0s}'.",
    .category = "Message",
    .code = "6087",
};
pub const module_resolution_kind_is_not_specified_using_ARG = DiagnosticMessage{
    .message = "Module resolution kind is not specified, using '{0s}'.",
    .category = "Message",
    .code = "6088",
};
pub const module_name_ARG_was_successfully_resolved_to_ARG = DiagnosticMessage{
    .message = "======== Module name '{0s}' was successfully resolved to '{1s}'. ========",
    .category = "Message",
    .code = "6089",
};
pub const module_name_ARG_was_not_resolved = DiagnosticMessage{
    .message = "======== Module name '{0s}' was not resolved. ========",
    .category = "Message",
    .code = "6090",
};
pub const paths_option_is_specified_looking_for_a_pattern_to_match_module_name_ARG = DiagnosticMessage{
    .message = "'paths' option is specified, looking for a pattern to match module name '{0s}'.",
    .category = "Message",
    .code = "6091",
};
pub const module_name_ARG_matched_pattern_ARG = DiagnosticMessage{
    .message = "Module name '{0s}', matched pattern '{1s}'.",
    .category = "Message",
    .code = "6092",
};
pub const trying_substitution_ARG_candidate_module_location_ARG = DiagnosticMessage{
    .message = "Trying substitution '{0s}', candidate module location: '{1s}'.",
    .category = "Message",
    .code = "6093",
};
pub const resolving_module_name_ARG_relative_to_base_url_ARG_ARG = DiagnosticMessage{
    .message = "Resolving module name '{0s}' relative to base url '{1s}' - '{2s}'.",
    .category = "Message",
    .code = "6094",
};
pub const loading_module_as_file_folder_candidate_module_location_ARG_target_file_types_ARG = DiagnosticMessage{
    .message = "Loading module as file / folder, candidate module location '{0s}', target file types: {1s}.",
    .category = "Message",
    .code = "6095",
};
pub const file_ARG_does_not_exist = DiagnosticMessage{
    .message = "File '{0s}' does not exist.",
    .category = "Message",
    .code = "6096",
};
pub const file_ARG_exists_use_it_as_a_name_resolution_result = DiagnosticMessage{
    .message = "File '{0s}' exists - use it as a name resolution result.",
    .category = "Message",
    .code = "6097",
};
pub const loading_module_ARG_from_node_modules_folder_target_file_types_ARG = DiagnosticMessage{
    .message = "Loading module '{0s}' from 'node_modules' folder, target file types: {1s}.",
    .category = "Message",
    .code = "6098",
};
pub const found_package_json_at_ARG = DiagnosticMessage{
    .message = "Found 'package.json' at '{0s}'.",
    .category = "Message",
    .code = "6099",
};
pub const package_json_does_not_have_a_ARG_field = DiagnosticMessage{
    .message = "'package.json' does not have a '{0s}' field.",
    .category = "Message",
    .code = "6100",
};
pub const package_json_has_ARG_field_ARG_that_references_ARG = DiagnosticMessage{
    .message = "'package.json' has '{0s}' field '{1s}' that references '{2s}'.",
    .category = "Message",
    .code = "6101",
};
pub const allow_javascript_files_to_be_compiled = DiagnosticMessage{
    .message = "Allow javascript files to be compiled.",
    .category = "Message",
    .code = "6102",
};
pub const checking_if_ARG_is_the_longest_matching_prefix_for_ARG_ARG = DiagnosticMessage{
    .message = "Checking if '{0s}' is the longest matching prefix for '{1s}' - '{2s}'.",
    .category = "Message",
    .code = "6104",
};
pub const expected_type_of_ARG_field_in_package_json_to_be_ARG_got_ARG = DiagnosticMessage{
    .message = "Expected type of '{0s}' field in 'package.json' to be '{1s}', got '{2s}'.",
    .category = "Message",
    .code = "6105",
};
pub const baseurl_option_is_set_to_ARG_using_this_value_to_resolve_non_relative_module_name_ARG = DiagnosticMessage{
    .message = "'baseUrl' option is set to '{0s}', using this value to resolve non-relative module name '{1s}'.",
    .category = "Message",
    .code = "6106",
};
pub const rootdirs_option_is_set_using_it_to_resolve_relative_module_name_ARG = DiagnosticMessage{
    .message = "'rootDirs' option is set, using it to resolve relative module name '{0s}'.",
    .category = "Message",
    .code = "6107",
};
pub const longest_matching_prefix_for_ARG_is_ARG = DiagnosticMessage{
    .message = "Longest matching prefix for '{0s}' is '{1s}'.",
    .category = "Message",
    .code = "6108",
};
pub const loading_ARG_from_the_root_dir_ARG_candidate_location_ARG = DiagnosticMessage{
    .message = "Loading '{0s}' from the root dir '{1s}', candidate location '{2s}'.",
    .category = "Message",
    .code = "6109",
};
pub const trying_other_entries_in_rootdirs = DiagnosticMessage{
    .message = "Trying other entries in 'rootDirs'.",
    .category = "Message",
    .code = "6110",
};
pub const module_resolution_using_rootdirs_has_failed = DiagnosticMessage{
    .message = "Module resolution using 'rootDirs' has failed.",
    .category = "Message",
    .code = "6111",
};
pub const do_not_emit_use_strict_directives_in_module_output = DiagnosticMessage{
    .message = "Do not emit 'use strict' directives in module output.",
    .category = "Message",
    .code = "6112",
};
pub const enable_strict_null_checks = DiagnosticMessage{
    .message = "Enable strict null checks.",
    .category = "Message",
    .code = "6113",
};
pub const unknown_option_excludes_did_you_mean_exclude = DiagnosticMessage{
    .message = "Unknown option 'excludes'. Did you mean 'exclude'?",
    .category = "Error",
    .code = "6114",
};
pub const raise_error_on_this_expressions_with_an_implied_any_type = DiagnosticMessage{
    .message = "Raise error on 'this' expressions with an implied 'any' type.",
    .category = "Message",
    .code = "6115",
};
pub const resolving_type_reference_directive_ARG_containing_file_ARG_root_directory_ARG = DiagnosticMessage{
    .message = "======== Resolving type reference directive '{0s}', containing file '{1s}', root directory '{2s}'. ========",
    .category = "Message",
    .code = "6116",
};
pub const type_reference_directive_ARG_was_successfully_resolved_to_ARG_primary_ARG = DiagnosticMessage{
    .message = "======== Type reference directive '{0s}' was successfully resolved to '{1s}', primary: {2s}. ========",
    .category = "Message",
    .code = "6119",
};
pub const type_reference_directive_ARG_was_not_resolved = DiagnosticMessage{
    .message = "======== Type reference directive '{0s}' was not resolved. ========",
    .category = "Message",
    .code = "6120",
};
pub const resolving_with_primary_search_path_ARG = DiagnosticMessage{
    .message = "Resolving with primary search path '{0s}'.",
    .category = "Message",
    .code = "6121",
};
pub const root_directory_cannot_be_determined_skipping_primary_search_paths = DiagnosticMessage{
    .message = "Root directory cannot be determined, skipping primary search paths.",
    .category = "Message",
    .code = "6122",
};
pub const resolving_type_reference_directive_ARG_containing_file_ARG_root_directory_not_set = DiagnosticMessage{
    .message = "======== Resolving type reference directive '{0s}', containing file '{1s}', root directory not set. ========",
    .category = "Message",
    .code = "6123",
};
pub const type_declaration_files_to_be_included_in_compilation = DiagnosticMessage{
    .message = "Type declaration files to be included in compilation.",
    .category = "Message",
    .code = "6124",
};
pub const looking_up_in_node_modules_folder_initial_location_ARG = DiagnosticMessage{
    .message = "Looking up in 'node_modules' folder, initial location '{0s}'.",
    .category = "Message",
    .code = "6125",
};
pub const containing_file_is_not_specified_and_root_directory_cannot_be_determined_skipping_lookup_in_node_modules_folder = DiagnosticMessage{
    .message = "Containing file is not specified and root directory cannot be determined, skipping lookup in 'node_modules' folder.",
    .category = "Message",
    .code = "6126",
};
pub const resolving_type_reference_directive_ARG_containing_file_not_set_root_directory_ARG = DiagnosticMessage{
    .message = "======== Resolving type reference directive '{0s}', containing file not set, root directory '{1s}'. ========",
    .category = "Message",
    .code = "6127",
};
pub const resolving_type_reference_directive_ARG_containing_file_not_set_root_directory_not_set = DiagnosticMessage{
    .message = "======== Resolving type reference directive '{0s}', containing file not set, root directory not set. ========",
    .category = "Message",
    .code = "6128",
};
pub const resolving_real_path_for_ARG_result_ARG = DiagnosticMessage{
    .message = "Resolving real path for '{0s}', result '{1s}'.",
    .category = "Message",
    .code = "6130",
};
pub const cannot_compile_modules_using_option_ARG_unless_the_module_flag_is_amd_or_system = DiagnosticMessage{
    .message = "Cannot compile modules using option '{0s}' unless the '--module' flag is 'amd' or 'system'.",
    .category = "Error",
    .code = "6131",
};
pub const file_name_ARG_has_a_ARG_extension_stripping_it = DiagnosticMessage{
    .message = "File name '{0s}' has a '{1s}' extension - stripping it.",
    .category = "Message",
    .code = "6132",
};
pub const ARG_is_declared_but_its_value_is_never_read = DiagnosticMessage{
    .message = "'{0s}' is declared but its value is never read.",
    .category = "Error",
    .code = "6133",
};
pub const report_errors_on_unused_locals = DiagnosticMessage{
    .message = "Report errors on unused locals.",
    .category = "Message",
    .code = "6134",
};
pub const report_errors_on_unused_parameters = DiagnosticMessage{
    .message = "Report errors on unused parameters.",
    .category = "Message",
    .code = "6135",
};
pub const the_maximum_dependency_depth_to_search_under_node_modules_and_load_javascript_files = DiagnosticMessage{
    .message = "The maximum dependency depth to search under node_modules and load JavaScript files.",
    .category = "Message",
    .code = "6136",
};
pub const cannot_import_type_declaration_files_consider_importing_ARG_instead_of_ARG = DiagnosticMessage{
    .message = "Cannot import type declaration files. Consider importing '{0s}' instead of '{1s}'.",
    .category = "Error",
    .code = "6137",
};
pub const property_ARG_is_declared_but_its_value_is_never_read = DiagnosticMessage{
    .message = "Property '{0s}' is declared but its value is never read.",
    .category = "Error",
    .code = "6138",
};
pub const import_emit_helpers_from_tslib = DiagnosticMessage{
    .message = "Import emit helpers from 'tslib'.",
    .category = "Message",
    .code = "6139",
};
pub const auto_discovery_for_typings_is_enabled_in_project_ARG_running_extra_resolution_pass_for_module_ARG_using_cache_location_ARG = DiagnosticMessage{
    .message = "Auto discovery for typings is enabled in project '{0s}'. Running extra resolution pass for module '{1s}' using cache location '{2s}'.",
    .category = "Error",
    .code = "6140",
};
pub const parse_in_strict_mode_and_emit_use_strict_for_each_source_file = DiagnosticMessage{
    .message = "Parse in strict mode and emit \"use strict\" for each source file.",
    .category = "Message",
    .code = "6141",
};
pub const module_ARG_was_resolved_to_ARG_but_jsx_is_not_set = DiagnosticMessage{
    .message = "Module '{0s}' was resolved to '{1s}', but '--jsx' is not set.",
    .category = "Error",
    .code = "6142",
};
pub const module_ARG_was_resolved_as_locally_declared_ambient_module_in_file_ARG = DiagnosticMessage{
    .message = "Module '{0s}' was resolved as locally declared ambient module in file '{1s}'.",
    .category = "Message",
    .code = "6144",
};
pub const module_ARG_was_resolved_as_ambient_module_declared_in_ARG_since_this_file_was_not_modified = DiagnosticMessage{
    .message = "Module '{0s}' was resolved as ambient module declared in '{1s}' since this file was not modified.",
    .category = "Message",
    .code = "6145",
};
pub const specify_the_jsx_factory_function_to_use_when_targeting_react_jsx_emit_e_g_react_createelement_or_h = DiagnosticMessage{
    .message = "Specify the JSX factory function to use when targeting 'react' JSX emit, e.g. 'React.createElement' or 'h'.",
    .category = "Message",
    .code = "6146",
};
pub const resolution_for_module_ARG_was_found_in_cache_from_location_ARG = DiagnosticMessage{
    .message = "Resolution for module '{0s}' was found in cache from location '{1s}'.",
    .category = "Message",
    .code = "6147",
};
pub const directory_ARG_does_not_exist_skipping_all_lookups_in_it = DiagnosticMessage{
    .message = "Directory '{0s}' does not exist, skipping all lookups in it.",
    .category = "Message",
    .code = "6148",
};
pub const show_diagnostic_information = DiagnosticMessage{
    .message = "Show diagnostic information.",
    .category = "Message",
    .code = "6149",
};
pub const show_verbose_diagnostic_information = DiagnosticMessage{
    .message = "Show verbose diagnostic information.",
    .category = "Message",
    .code = "6150",
};
pub const emit_a_single_file_with_source_maps_instead_of_having_a_separate_file = DiagnosticMessage{
    .message = "Emit a single file with source maps instead of having a separate file.",
    .category = "Message",
    .code = "6151",
};
pub const emit_the_source_alongside_the_sourcemaps_within_a_single_file_requires_inlinesourcemap_or_sourcemap_to_be_set = DiagnosticMessage{
    .message = "Emit the source alongside the sourcemaps within a single file; requires '--inlineSourceMap' or '--sourceMap' to be set.",
    .category = "Message",
    .code = "6152",
};
pub const transpile_each_file_as_a_separate_module_similar_to_ts_transpilemodule = DiagnosticMessage{
    .message = "Transpile each file as a separate module (similar to 'ts.transpileModule').",
    .category = "Message",
    .code = "6153",
};
pub const print_names_of_generated_files_part_of_the_compilation = DiagnosticMessage{
    .message = "Print names of generated files part of the compilation.",
    .category = "Message",
    .code = "6154",
};
pub const print_names_of_files_part_of_the_compilation = DiagnosticMessage{
    .message = "Print names of files part of the compilation.",
    .category = "Message",
    .code = "6155",
};
pub const the_locale_used_when_displaying_messages_to_the_user_e_g_en_us = DiagnosticMessage{
    .message = "The locale used when displaying messages to the user (e.g. 'en-us')",
    .category = "Message",
    .code = "6156",
};
pub const do_not_generate_custom_helper_functions_like_extends_in_compiled_output = DiagnosticMessage{
    .message = "Do not generate custom helper functions like '__extends' in compiled output.",
    .category = "Message",
    .code = "6157",
};
pub const do_not_include_the_default_library_file_lib_d_ts = DiagnosticMessage{
    .message = "Do not include the default library file (lib.d.ts).",
    .category = "Message",
    .code = "6158",
};
pub const do_not_add_triple_slash_references_or_imported_modules_to_the_list_of_compiled_files = DiagnosticMessage{
    .message = "Do not add triple-slash references or imported modules to the list of compiled files.",
    .category = "Message",
    .code = "6159",
};
pub const deprecated_use_skiplibcheck_instead_skip_type_checking_of_default_library_declaration_files = DiagnosticMessage{
    .message = "[Deprecated] Use '--skipLibCheck' instead. Skip type checking of default library declaration files.",
    .category = "Message",
    .code = "6160",
};
pub const list_of_folders_to_include_type_definitions_from = DiagnosticMessage{
    .message = "List of folders to include type definitions from.",
    .category = "Message",
    .code = "6161",
};
pub const disable_size_limitations_on_javascript_projects = DiagnosticMessage{
    .message = "Disable size limitations on JavaScript projects.",
    .category = "Message",
    .code = "6162",
};
pub const the_character_set_of_the_input_files = DiagnosticMessage{
    .message = "The character set of the input files.",
    .category = "Message",
    .code = "6163",
};
pub const skipping_module_ARG_that_looks_like_an_absolute_uri_target_file_types_ARG = DiagnosticMessage{
    .message = "Skipping module '{0s}' that looks like an absolute URI, target file types: {1s}.",
    .category = "Message",
    .code = "6164",
};
pub const do_not_truncate_error_messages = DiagnosticMessage{
    .message = "Do not truncate error messages.",
    .category = "Message",
    .code = "6165",
};
pub const output_directory_for_generated_declaration_files = DiagnosticMessage{
    .message = "Output directory for generated declaration files.",
    .category = "Message",
    .code = "6166",
};
pub const a_series_of_entries_which_re_map_imports_to_lookup_locations_relative_to_the_baseurl = DiagnosticMessage{
    .message = "A series of entries which re-map imports to lookup locations relative to the 'baseUrl'.",
    .category = "Message",
    .code = "6167",
};
pub const list_of_root_folders_whose_combined_content_represents_the_structure_of_the_project_at_runtime = DiagnosticMessage{
    .message = "List of root folders whose combined content represents the structure of the project at runtime.",
    .category = "Message",
    .code = "6168",
};
pub const show_all_compiler_options = DiagnosticMessage{
    .message = "Show all compiler options.",
    .category = "Message",
    .code = "6169",
};
pub const deprecated_use_outfile_instead_concatenate_and_emit_output_to_single_file = DiagnosticMessage{
    .message = "[Deprecated] Use '--outFile' instead. Concatenate and emit output to single file",
    .category = "Message",
    .code = "6170",
};
pub const command_line_options = DiagnosticMessage{
    .message = "Command-line Options",
    .category = "Message",
    .code = "6171",
};
pub const provide_full_support_for_iterables_in_for_of_spread_and_destructuring_when_targeting_es5 = DiagnosticMessage{
    .message = "Provide full support for iterables in 'for-of', spread, and destructuring when targeting 'ES5'.",
    .category = "Message",
    .code = "6179",
};
pub const enable_all_strict_type_checking_options = DiagnosticMessage{
    .message = "Enable all strict type-checking options.",
    .category = "Message",
    .code = "6180",
};
pub const scoped_package_detected_looking_in_ARG = DiagnosticMessage{
    .message = "Scoped package detected, looking in '{0s}'",
    .category = "Message",
    .code = "6182",
};
pub const reusing_resolution_of_module_ARG_from_ARG_of_old_program_it_was_successfully_resolved_to_ARG = DiagnosticMessage{
    .message = "Reusing resolution of module '{0s}' from '{1s}' of old program, it was successfully resolved to '{2s}'.",
    .category = "Message",
    .code = "6183",
};
pub const reusing_resolution_of_module_ARG_from_ARG_of_old_program_it_was_successfully_resolved_to_ARG_with_package_id_ARG = DiagnosticMessage{
    .message = "Reusing resolution of module '{0s}' from '{1s}' of old program, it was successfully resolved to '{2s}' with Package ID '{3s}'.",
    .category = "Message",
    .code = "6184",
};
pub const enable_strict_checking_of_function_types = DiagnosticMessage{
    .message = "Enable strict checking of function types.",
    .category = "Message",
    .code = "6186",
};
pub const enable_strict_checking_of_property_initialization_in_classes = DiagnosticMessage{
    .message = "Enable strict checking of property initialization in classes.",
    .category = "Message",
    .code = "6187",
};
pub const numeric_separators_are_not_allowed_here = DiagnosticMessage{
    .message = "Numeric separators are not allowed here.",
    .category = "Error",
    .code = "6188",
};
pub const multiple_consecutive_numeric_separators_are_not_permitted = DiagnosticMessage{
    .message = "Multiple consecutive numeric separators are not permitted.",
    .category = "Error",
    .code = "6189",
};
pub const whether_to_keep_outdated_console_output_in_watch_mode_instead_of_clearing_the_screen = DiagnosticMessage{
    .message = "Whether to keep outdated console output in watch mode instead of clearing the screen.",
    .category = "Message",
    .code = "6191",
};
pub const all_imports_in_import_declaration_are_unused = DiagnosticMessage{
    .message = "All imports in import declaration are unused.",
    .category = "Error",
    .code = "6192",
};
pub const found_1_error_watching_for_file_changes = DiagnosticMessage{
    .message = "Found 1 error. Watching for file changes.",
    .category = "Message",
    .code = "6193",
};
pub const found_ARG_errors_watching_for_file_changes = DiagnosticMessage{
    .message = "Found {0s} errors. Watching for file changes.",
    .category = "Message",
    .code = "6194",
};
pub const resolve_keyof_to_string_valued_property_names_only_no_numbers_or_symbols = DiagnosticMessage{
    .message = "Resolve 'keyof' to string valued property names only (no numbers or symbols).",
    .category = "Message",
    .code = "6195",
};
pub const ARG_is_declared_but_never_used = DiagnosticMessage{
    .message = "'{0s}' is declared but never used.",
    .category = "Error",
    .code = "6196",
};
pub const include_modules_imported_with_json_extension = DiagnosticMessage{
    .message = "Include modules imported with '.json' extension",
    .category = "Message",
    .code = "6197",
};
pub const all_destructured_elements_are_unused = DiagnosticMessage{
    .message = "All destructured elements are unused.",
    .category = "Error",
    .code = "6198",
};
pub const all_variables_are_unused = DiagnosticMessage{
    .message = "All variables are unused.",
    .category = "Error",
    .code = "6199",
};
pub const definitions_of_the_following_identifiers_conflict_with_those_in_another_file_ARG = DiagnosticMessage{
    .message = "Definitions of the following identifiers conflict with those in another file: {0s}",
    .category = "Error",
    .code = "6200",
};
pub const conflicts_are_in_this_file = DiagnosticMessage{
    .message = "Conflicts are in this file.",
    .category = "Message",
    .code = "6201",
};
pub const project_references_may_not_form_a_circular_graph_cycle_detected_ARG = DiagnosticMessage{
    .message = "Project references may not form a circular graph. Cycle detected: {0s}",
    .category = "Error",
    .code = "6202",
};
pub const ARG_was_also_declared_here = DiagnosticMessage{
    .message = "'{0s}' was also declared here.",
    .category = "Message",
    .code = "6203",
};
pub const and_here = DiagnosticMessage{
    .message = "and here.",
    .category = "Message",
    .code = "6204",
};
pub const all_type_parameters_are_unused = DiagnosticMessage{
    .message = "All type parameters are unused.",
    .category = "Error",
    .code = "6205",
};
pub const package_json_has_a_typesversions_field_with_version_specific_path_mappings = DiagnosticMessage{
    .message = "'package.json' has a 'typesVersions' field with version-specific path mappings.",
    .category = "Message",
    .code = "6206",
};
pub const package_json_does_not_have_a_typesversions_entry_that_matches_version_ARG = DiagnosticMessage{
    .message = "'package.json' does not have a 'typesVersions' entry that matches version '{0s}'.",
    .category = "Message",
    .code = "6207",
};
pub const package_json_has_a_typesversions_entry_ARG_that_matches_compiler_version_ARG_looking_for_a_pattern_to_match_module_name_ARG = DiagnosticMessage{
    .message = "'package.json' has a 'typesVersions' entry '{0s}' that matches compiler version '{1s}', looking for a pattern to match module name '{2s}'.",
    .category = "Message",
    .code = "6208",
};
pub const package_json_has_a_typesversions_entry_ARG_that_is_not_a_valid_semver_range = DiagnosticMessage{
    .message = "'package.json' has a 'typesVersions' entry '{0s}' that is not a valid semver range.",
    .category = "Message",
    .code = "6209",
};
pub const an_argument_for_ARG_was_not_provided = DiagnosticMessage{
    .message = "An argument for '{0s}' was not provided.",
    .category = "Message",
    .code = "6210",
};
pub const an_argument_matching_this_binding_pattern_was_not_provided = DiagnosticMessage{
    .message = "An argument matching this binding pattern was not provided.",
    .category = "Message",
    .code = "6211",
};
pub const did_you_mean_to_call_this_expression = DiagnosticMessage{
    .message = "Did you mean to call this expression?",
    .category = "Message",
    .code = "6212",
};
pub const did_you_mean_to_use_new_with_this_expression = DiagnosticMessage{
    .message = "Did you mean to use 'new' with this expression?",
    .category = "Message",
    .code = "6213",
};
pub const enable_strict_bind_call_and_apply_methods_on_functions = DiagnosticMessage{
    .message = "Enable strict 'bind', 'call', and 'apply' methods on functions.",
    .category = "Message",
    .code = "6214",
};
pub const using_compiler_options_of_project_reference_redirect_ARG = DiagnosticMessage{
    .message = "Using compiler options of project reference redirect '{0s}'.",
    .category = "Message",
    .code = "6215",
};
pub const found_1_error = DiagnosticMessage{
    .message = "Found 1 error.",
    .category = "Message",
    .code = "6216",
};
pub const found_ARG_errors = DiagnosticMessage{
    .message = "Found {0s} errors.",
    .category = "Message",
    .code = "6217",
};
pub const module_name_ARG_was_successfully_resolved_to_ARG_with_package_id_ARG = DiagnosticMessage{
    .message = "======== Module name '{0s}' was successfully resolved to '{1s}' with Package ID '{2s}'. ========",
    .category = "Message",
    .code = "6218",
};
pub const type_reference_directive_ARG_was_successfully_resolved_to_ARG_with_package_id_ARG_primary_ARG = DiagnosticMessage{
    .message = "======== Type reference directive '{0s}' was successfully resolved to '{1s}' with Package ID '{2s}', primary: {3s}. ========",
    .category = "Message",
    .code = "6219",
};
pub const package_json_had_a_falsy_ARG_field = DiagnosticMessage{
    .message = "'package.json' had a falsy '{0s}' field.",
    .category = "Message",
    .code = "6220",
};
pub const disable_use_of_source_files_instead_of_declaration_files_from_referenced_projects = DiagnosticMessage{
    .message = "Disable use of source files instead of declaration files from referenced projects.",
    .category = "Message",
    .code = "6221",
};
pub const emit_class_fields_with_define_instead_of_set = DiagnosticMessage{
    .message = "Emit class fields with Define instead of Set.",
    .category = "Message",
    .code = "6222",
};
pub const generates_a_cpu_profile = DiagnosticMessage{
    .message = "Generates a CPU profile.",
    .category = "Message",
    .code = "6223",
};
pub const disable_solution_searching_for_this_project = DiagnosticMessage{
    .message = "Disable solution searching for this project.",
    .category = "Message",
    .code = "6224",
};
pub const specify_strategy_for_watching_file_fixedpollinginterval_default_prioritypollinginterval_dynamicprioritypolling_fixedchunksizepolling_usefsevents_usefseventsonparentdirectory = DiagnosticMessage{
    .message = "Specify strategy for watching file: 'FixedPollingInterval' (default), 'PriorityPollingInterval', 'DynamicPriorityPolling', 'FixedChunkSizePolling', 'UseFsEvents', 'UseFsEventsOnParentDirectory'.",
    .category = "Message",
    .code = "6225",
};
pub const specify_strategy_for_watching_directory_on_platforms_that_don_t_support_recursive_watching_natively_usefsevents_default_fixedpollinginterval_dynamicprioritypolling_fixedchunksizepolling = DiagnosticMessage{
    .message = "Specify strategy for watching directory on platforms that don't support recursive watching natively: 'UseFsEvents' (default), 'FixedPollingInterval', 'DynamicPriorityPolling', 'FixedChunkSizePolling'.",
    .category = "Message",
    .code = "6226",
};
pub const specify_strategy_for_creating_a_polling_watch_when_it_fails_to_create_using_file_system_events_fixedinterval_default_priorityinterval_dynamicpriority_fixedchunksize = DiagnosticMessage{
    .message = "Specify strategy for creating a polling watch when it fails to create using file system events: 'FixedInterval' (default), 'PriorityInterval', 'DynamicPriority', 'FixedChunkSize'.",
    .category = "Message",
    .code = "6227",
};
pub const tag_ARG_expects_at_least_ARG_arguments_but_the_jsx_factory_ARG_provides_at_most_ARG = DiagnosticMessage{
    .message = "Tag '{0s}' expects at least '{1s}' arguments, but the JSX factory '{2s}' provides at most '{3s}'.",
    .category = "Error",
    .code = "6229",
};
pub const option_ARG_can_only_be_specified_in_tsconfig_json_file_or_set_to_false_or_null_on_command_line = DiagnosticMessage{
    .message = "Option '{0s}' can only be specified in 'tsconfig.json' file or set to 'false' or 'null' on command line.",
    .category = "Error",
    .code = "6230",
};
pub const could_not_resolve_the_path_ARG_with_the_extensions_ARG = DiagnosticMessage{
    .message = "Could not resolve the path '{0s}' with the extensions: {1s}.",
    .category = "Error",
    .code = "6231",
};
pub const declaration_augments_declaration_in_another_file_this_cannot_be_serialized = DiagnosticMessage{
    .message = "Declaration augments declaration in another file. This cannot be serialized.",
    .category = "Error",
    .code = "6232",
};
pub const this_is_the_declaration_being_augmented_consider_moving_the_augmenting_declaration_into_the_same_file = DiagnosticMessage{
    .message = "This is the declaration being augmented. Consider moving the augmenting declaration into the same file.",
    .category = "Error",
    .code = "6233",
};
pub const this_expression_is_not_callable_because_it_is_a_get_accessor_did_you_mean_to_use_it_without = DiagnosticMessage{
    .message = "This expression is not callable because it is a 'get' accessor. Did you mean to use it without '()'?",
    .category = "Error",
    .code = "6234",
};
pub const disable_loading_referenced_projects = DiagnosticMessage{
    .message = "Disable loading referenced projects.",
    .category = "Message",
    .code = "6235",
};
pub const arguments_for_the_rest_parameter_ARG_were_not_provided = DiagnosticMessage{
    .message = "Arguments for the rest parameter '{0s}' were not provided.",
    .category = "Error",
    .code = "6236",
};
pub const generates_an_event_trace_and_a_list_of_types = DiagnosticMessage{
    .message = "Generates an event trace and a list of types.",
    .category = "Message",
    .code = "6237",
};
pub const specify_the_module_specifier_to_be_used_to_import_the_jsx_and_jsxs_factory_functions_from_eg_react = DiagnosticMessage{
    .message = "Specify the module specifier to be used to import the 'jsx' and 'jsxs' factory functions from. eg, react",
    .category = "Error",
    .code = "6238",
};
pub const file_ARG_exists_according_to_earlier_cached_lookups = DiagnosticMessage{
    .message = "File '{0s}' exists according to earlier cached lookups.",
    .category = "Message",
    .code = "6239",
};
pub const file_ARG_does_not_exist_according_to_earlier_cached_lookups = DiagnosticMessage{
    .message = "File '{0s}' does not exist according to earlier cached lookups.",
    .category = "Message",
    .code = "6240",
};
pub const resolution_for_type_reference_directive_ARG_was_found_in_cache_from_location_ARG = DiagnosticMessage{
    .message = "Resolution for type reference directive '{0s}' was found in cache from location '{1s}'.",
    .category = "Message",
    .code = "6241",
};
pub const resolving_type_reference_directive_ARG_containing_file_ARG = DiagnosticMessage{
    .message = "======== Resolving type reference directive '{0s}', containing file '{1s}'. ========",
    .category = "Message",
    .code = "6242",
};
pub const interpret_optional_property_types_as_written_rather_than_adding_undefined = DiagnosticMessage{
    .message = "Interpret optional property types as written, rather than adding 'undefined'.",
    .category = "Message",
    .code = "6243",
};
pub const modules = DiagnosticMessage{
    .message = "Modules",
    .category = "Message",
    .code = "6244",
};
pub const file_management = DiagnosticMessage{
    .message = "File Management",
    .category = "Message",
    .code = "6245",
};
pub const emit = DiagnosticMessage{
    .message = "Emit",
    .category = "Message",
    .code = "6246",
};
pub const javascript_support = DiagnosticMessage{
    .message = "JavaScript Support",
    .category = "Message",
    .code = "6247",
};
pub const type_checking = DiagnosticMessage{
    .message = "Type Checking",
    .category = "Message",
    .code = "6248",
};
pub const editor_support = DiagnosticMessage{
    .message = "Editor Support",
    .category = "Message",
    .code = "6249",
};
pub const watch_and_build_modes = DiagnosticMessage{
    .message = "Watch and Build Modes",
    .category = "Message",
    .code = "6250",
};
pub const compiler_diagnostics = DiagnosticMessage{
    .message = "Compiler Diagnostics",
    .category = "Message",
    .code = "6251",
};
pub const interop_constraints = DiagnosticMessage{
    .message = "Interop Constraints",
    .category = "Message",
    .code = "6252",
};
pub const backwards_compatibility = DiagnosticMessage{
    .message = "Backwards Compatibility",
    .category = "Message",
    .code = "6253",
};
pub const language_and_environment = DiagnosticMessage{
    .message = "Language and Environment",
    .category = "Message",
    .code = "6254",
};
pub const projects = DiagnosticMessage{
    .message = "Projects",
    .category = "Message",
    .code = "6255",
};
pub const output_formatting = DiagnosticMessage{
    .message = "Output Formatting",
    .category = "Message",
    .code = "6256",
};
pub const completeness = DiagnosticMessage{
    .message = "Completeness",
    .category = "Message",
    .code = "6257",
};
pub const ARG_should_be_set_inside_the_compileroptions_object_of_the_config_json_file = DiagnosticMessage{
    .message = "'{0s}' should be set inside the 'compilerOptions' object of the config json file",
    .category = "Error",
    .code = "6258",
};
pub const found_1_error_in_ARG = DiagnosticMessage{
    .message = "Found 1 error in {0s}",
    .category = "Message",
    .code = "6259",
};
pub const found_ARG_errors_in_the_same_file_starting_at_ARG = DiagnosticMessage{
    .message = "Found {0s} errors in the same file, starting at: {1s}",
    .category = "Message",
    .code = "6260",
};
pub const found_ARG_errors_in_ARG_files = DiagnosticMessage{
    .message = "Found {0s} errors in {1s} files.",
    .category = "Message",
    .code = "6261",
};
pub const file_name_ARG_has_a_ARG_extension_looking_up_ARG_instead = DiagnosticMessage{
    .message = "File name '{0s}' has a '{1s}' extension - looking up '{2s}' instead.",
    .category = "Message",
    .code = "6262",
};
pub const module_ARG_was_resolved_to_ARG_but_allowarbitraryextensions_is_not_set = DiagnosticMessage{
    .message = "Module '{0s}' was resolved to '{1s}', but '--allowArbitraryExtensions' is not set.",
    .category = "Error",
    .code = "6263",
};
pub const enable_importing_files_with_any_extension_provided_a_declaration_file_is_present = DiagnosticMessage{
    .message = "Enable importing files with any extension, provided a declaration file is present.",
    .category = "Message",
    .code = "6264",
};
pub const resolving_type_reference_directive_for_program_that_specifies_custom_typeroots_skipping_lookup_in_node_modules_folder = DiagnosticMessage{
    .message = "Resolving type reference directive for program that specifies custom typeRoots, skipping lookup in 'node_modules' folder.",
    .category = "Message",
    .code = "6265",
};
pub const option_ARG_can_only_be_specified_on_command_line = DiagnosticMessage{
    .message = "Option '{0s}' can only be specified on command line.",
    .category = "Error",
    .code = "6266",
};
pub const directory_ARG_has_no_containing_package_json_scope_imports_will_not_resolve = DiagnosticMessage{
    .message = "Directory '{0s}' has no containing package.json scope. Imports will not resolve.",
    .category = "Message",
    .code = "6270",
};
pub const import_specifier_ARG_does_not_exist_in_package_json_scope_at_path_ARG = DiagnosticMessage{
    .message = "Import specifier '{0s}' does not exist in package.json scope at path '{1s}'.",
    .category = "Message",
    .code = "6271",
};
pub const invalid_import_specifier_ARG_has_no_possible_resolutions = DiagnosticMessage{
    .message = "Invalid import specifier '{0s}' has no possible resolutions.",
    .category = "Message",
    .code = "6272",
};
pub const package_json_scope_ARG_has_no_imports_defined = DiagnosticMessage{
    .message = "package.json scope '{0s}' has no imports defined.",
    .category = "Message",
    .code = "6273",
};
pub const package_json_scope_ARG_explicitly_maps_specifier_ARG_to_null = DiagnosticMessage{
    .message = "package.json scope '{0s}' explicitly maps specifier '{1s}' to null.",
    .category = "Message",
    .code = "6274",
};
pub const package_json_scope_ARG_has_invalid_type_for_target_of_specifier_ARG = DiagnosticMessage{
    .message = "package.json scope '{0s}' has invalid type for target of specifier '{1s}'",
    .category = "Message",
    .code = "6275",
};
pub const export_specifier_ARG_does_not_exist_in_package_json_scope_at_path_ARG = DiagnosticMessage{
    .message = "Export specifier '{0s}' does not exist in package.json scope at path '{1s}'.",
    .category = "Message",
    .code = "6276",
};
pub const resolution_of_non_relative_name_failed_trying_with_modern_node_resolution_features_disabled_to_see_if_npm_library_needs_configuration_update = DiagnosticMessage{
    .message = "Resolution of non-relative name failed; trying with modern Node resolution features disabled to see if npm library needs configuration update.",
    .category = "Message",
    .code = "6277",
};
pub const there_are_types_at_ARG_but_this_result_could_not_be_resolved_when_respecting_package_json_exports_the_ARG_library_may_need_to_update_its_package_json_or_typings = DiagnosticMessage{
    .message = "There are types at '{0s}', but this result could not be resolved when respecting package.json \"exports\". The '{1s}' library may need to update its package.json or typings.",
    .category = "Message",
    .code = "6278",
};
pub const resolution_of_non_relative_name_failed_trying_with_moduleresolution_bundler_to_see_if_project_may_need_configuration_update = DiagnosticMessage{
    .message = "Resolution of non-relative name failed; trying with '--moduleResolution bundler' to see if project may need configuration update.",
    .category = "Message",
    .code = "6279",
};
pub const there_are_types_at_ARG_but_this_result_could_not_be_resolved_under_your_current_moduleresolution_setting_consider_updating_to_node16_nodenext_or_bundler = DiagnosticMessage{
    .message = "There are types at '{0s}', but this result could not be resolved under your current 'moduleResolution' setting. Consider updating to 'node16', 'nodenext', or 'bundler'.",
    .category = "Message",
    .code = "6280",
};
pub const package_json_has_a_peerdependencies_field = DiagnosticMessage{
    .message = "'package.json' has a 'peerDependencies' field.",
    .category = "Message",
    .code = "6281",
};
pub const found_peerdependency_ARG_with_ARG_version = DiagnosticMessage{
    .message = "Found peerDependency '{0s}' with '{1s}' version.",
    .category = "Message",
    .code = "6282",
};
pub const failed_to_find_peerdependency_ARG = DiagnosticMessage{
    .message = "Failed to find peerDependency '{0s}'.",
    .category = "Message",
    .code = "6283",
};
pub const enable_project_compilation = DiagnosticMessage{
    .message = "Enable project compilation",
    .category = "Message",
    .code = "6302",
};
pub const composite_projects_may_not_disable_declaration_emit = DiagnosticMessage{
    .message = "Composite projects may not disable declaration emit.",
    .category = "Error",
    .code = "6304",
};
pub const output_file_ARG_has_not_been_built_from_source_file_ARG = DiagnosticMessage{
    .message = "Output file '{0s}' has not been built from source file '{1s}'.",
    .category = "Error",
    .code = "6305",
};
pub const referenced_project_ARG_must_have_setting_composite_true = DiagnosticMessage{
    .message = "Referenced project '{0s}' must have setting \"composite\": true.",
    .category = "Error",
    .code = "6306",
};
pub const file_ARG_is_not_listed_within_the_file_list_of_project_ARG_projects_must_list_all_files_or_use_an_include_pattern = DiagnosticMessage{
    .message = "File '{0s}' is not listed within the file list of project '{1s}'. Projects must list all files or use an 'include' pattern.",
    .category = "Error",
    .code = "6307",
};
pub const referenced_project_ARG_may_not_disable_emit = DiagnosticMessage{
    .message = "Referenced project '{0s}' may not disable emit.",
    .category = "Error",
    .code = "6310",
};
pub const project_ARG_is_out_of_date_because_output_ARG_is_older_than_input_ARG = DiagnosticMessage{
    .message = "Project '{0s}' is out of date because output '{1s}' is older than input '{2s}'",
    .category = "Message",
    .code = "6350",
};
pub const project_ARG_is_up_to_date_because_newest_input_ARG_is_older_than_output_ARG = DiagnosticMessage{
    .message = "Project '{0s}' is up to date because newest input '{1s}' is older than output '{2s}'",
    .category = "Message",
    .code = "6351",
};
pub const project_ARG_is_out_of_date_because_output_file_ARG_does_not_exist = DiagnosticMessage{
    .message = "Project '{0s}' is out of date because output file '{1s}' does not exist",
    .category = "Message",
    .code = "6352",
};
pub const project_ARG_is_out_of_date_because_its_dependency_ARG_is_out_of_date = DiagnosticMessage{
    .message = "Project '{0s}' is out of date because its dependency '{1s}' is out of date",
    .category = "Message",
    .code = "6353",
};
pub const project_ARG_is_up_to_date_with_d_ts_files_from_its_dependencies = DiagnosticMessage{
    .message = "Project '{0s}' is up to date with .d.ts files from its dependencies",
    .category = "Message",
    .code = "6354",
};
pub const projects_in_this_build_ARG = DiagnosticMessage{
    .message = "Projects in this build: {0s}",
    .category = "Message",
    .code = "6355",
};
pub const a_non_dry_build_would_delete_the_following_files_ARG = DiagnosticMessage{
    .message = "A non-dry build would delete the following files: {0s}",
    .category = "Message",
    .code = "6356",
};
pub const a_non_dry_build_would_build_project_ARG = DiagnosticMessage{
    .message = "A non-dry build would build project '{0s}'",
    .category = "Message",
    .code = "6357",
};
pub const building_project_ARG = DiagnosticMessage{
    .message = "Building project '{0s}'...",
    .category = "Message",
    .code = "6358",
};
pub const updating_output_timestamps_of_project_ARG = DiagnosticMessage{
    .message = "Updating output timestamps of project '{0s}'...",
    .category = "Message",
    .code = "6359",
};
pub const project_ARG_is_up_to_date = DiagnosticMessage{
    .message = "Project '{0s}' is up to date",
    .category = "Message",
    .code = "6361",
};
pub const skipping_build_of_project_ARG_because_its_dependency_ARG_has_errors = DiagnosticMessage{
    .message = "Skipping build of project '{0s}' because its dependency '{1s}' has errors",
    .category = "Message",
    .code = "6362",
};
pub const project_ARG_can_t_be_built_because_its_dependency_ARG_has_errors = DiagnosticMessage{
    .message = "Project '{0s}' can't be built because its dependency '{1s}' has errors",
    .category = "Message",
    .code = "6363",
};
pub const build_one_or_more_projects_and_their_dependencies_if_out_of_date = DiagnosticMessage{
    .message = "Build one or more projects and their dependencies, if out of date",
    .category = "Message",
    .code = "6364",
};
pub const delete_the_outputs_of_all_projects = DiagnosticMessage{
    .message = "Delete the outputs of all projects.",
    .category = "Message",
    .code = "6365",
};
pub const show_what_would_be_built_or_deleted_if_specified_with_clean = DiagnosticMessage{
    .message = "Show what would be built (or deleted, if specified with '--clean')",
    .category = "Message",
    .code = "6367",
};
pub const option_build_must_be_the_first_command_line_argument = DiagnosticMessage{
    .message = "Option '--build' must be the first command line argument.",
    .category = "Error",
    .code = "6369",
};
pub const options_ARG_and_ARG_cannot_be_combined = DiagnosticMessage{
    .message = "Options '{0s}' and '{1s}' cannot be combined.",
    .category = "Error",
    .code = "6370",
};
pub const updating_unchanged_output_timestamps_of_project_ARG = DiagnosticMessage{
    .message = "Updating unchanged output timestamps of project '{0s}'...",
    .category = "Message",
    .code = "6371",
};
pub const a_non_dry_build_would_update_timestamps_for_output_of_project_ARG = DiagnosticMessage{
    .message = "A non-dry build would update timestamps for output of project '{0s}'",
    .category = "Message",
    .code = "6374",
};
pub const cannot_write_file_ARG_because_it_will_overwrite_tsbuildinfo_file_generated_by_referenced_project_ARG = DiagnosticMessage{
    .message = "Cannot write file '{0s}' because it will overwrite '.tsbuildinfo' file generated by referenced project '{1s}'",
    .category = "Error",
    .code = "6377",
};
pub const composite_projects_may_not_disable_incremental_compilation = DiagnosticMessage{
    .message = "Composite projects may not disable incremental compilation.",
    .category = "Error",
    .code = "6379",
};
pub const specify_file_to_store_incremental_compilation_information = DiagnosticMessage{
    .message = "Specify file to store incremental compilation information",
    .category = "Message",
    .code = "6380",
};
pub const project_ARG_is_out_of_date_because_output_for_it_was_generated_with_version_ARG_that_differs_with_current_version_ARG = DiagnosticMessage{
    .message = "Project '{0s}' is out of date because output for it was generated with version '{1s}' that differs with current version '{2s}'",
    .category = "Message",
    .code = "6381",
};
pub const skipping_build_of_project_ARG_because_its_dependency_ARG_was_not_built = DiagnosticMessage{
    .message = "Skipping build of project '{0s}' because its dependency '{1s}' was not built",
    .category = "Message",
    .code = "6382",
};
pub const project_ARG_can_t_be_built_because_its_dependency_ARG_was_not_built = DiagnosticMessage{
    .message = "Project '{0s}' can't be built because its dependency '{1s}' was not built",
    .category = "Message",
    .code = "6383",
};
pub const have_recompiles_in_incremental_and_watch_assume_that_changes_within_a_file_will_only_affect_files_directly_depending_on_it = DiagnosticMessage{
    .message = "Have recompiles in '--incremental' and '--watch' assume that changes within a file will only affect files directly depending on it.",
    .category = "Message",
    .code = "6384",
};
pub const ARG_is_deprecated = DiagnosticMessage{
    .message = "'{0s}' is deprecated.",
    .category = "Suggestion",
    .code = "6385",
};
pub const performance_timings_for_diagnostics_or_extendeddiagnostics_are_not_available_in_this_session_a_native_implementation_of_the_web_performance_api_could_not_be_found = DiagnosticMessage{
    .message = "Performance timings for '--diagnostics' or '--extendedDiagnostics' are not available in this session. A native implementation of the Web Performance API could not be found.",
    .category = "Message",
    .code = "6386",
};
pub const the_signature_ARG_of_ARG_is_deprecated = DiagnosticMessage{
    .message = "The signature '{0s}' of '{1s}' is deprecated.",
    .category = "Suggestion",
    .code = "6387",
};
pub const project_ARG_is_being_forcibly_rebuilt = DiagnosticMessage{
    .message = "Project '{0s}' is being forcibly rebuilt",
    .category = "Message",
    .code = "6388",
};
pub const reusing_resolution_of_module_ARG_from_ARG_of_old_program_it_was_not_resolved = DiagnosticMessage{
    .message = "Reusing resolution of module '{0s}' from '{1s}' of old program, it was not resolved.",
    .category = "Message",
    .code = "6389",
};
pub const reusing_resolution_of_type_reference_directive_ARG_from_ARG_of_old_program_it_was_successfully_resolved_to_ARG = DiagnosticMessage{
    .message = "Reusing resolution of type reference directive '{0s}' from '{1s}' of old program, it was successfully resolved to '{2s}'.",
    .category = "Message",
    .code = "6390",
};
pub const reusing_resolution_of_type_reference_directive_ARG_from_ARG_of_old_program_it_was_successfully_resolved_to_ARG_with_package_id_ARG = DiagnosticMessage{
    .message = "Reusing resolution of type reference directive '{0s}' from '{1s}' of old program, it was successfully resolved to '{2s}' with Package ID '{3s}'.",
    .category = "Message",
    .code = "6391",
};
pub const reusing_resolution_of_type_reference_directive_ARG_from_ARG_of_old_program_it_was_not_resolved = DiagnosticMessage{
    .message = "Reusing resolution of type reference directive '{0s}' from '{1s}' of old program, it was not resolved.",
    .category = "Message",
    .code = "6392",
};
pub const reusing_resolution_of_module_ARG_from_ARG_found_in_cache_from_location_ARG_it_was_successfully_resolved_to_ARG = DiagnosticMessage{
    .message = "Reusing resolution of module '{0s}' from '{1s}' found in cache from location '{2s}', it was successfully resolved to '{3s}'.",
    .category = "Message",
    .code = "6393",
};
pub const reusing_resolution_of_module_ARG_from_ARG_found_in_cache_from_location_ARG_it_was_successfully_resolved_to_ARG_with_package_id_ARG = DiagnosticMessage{
    .message = "Reusing resolution of module '{0s}' from '{1s}' found in cache from location '{2s}', it was successfully resolved to '{3s}' with Package ID '{4s}'.",
    .category = "Message",
    .code = "6394",
};
pub const reusing_resolution_of_module_ARG_from_ARG_found_in_cache_from_location_ARG_it_was_not_resolved = DiagnosticMessage{
    .message = "Reusing resolution of module '{0s}' from '{1s}' found in cache from location '{2s}', it was not resolved.",
    .category = "Message",
    .code = "6395",
};
pub const reusing_resolution_of_type_reference_directive_ARG_from_ARG_found_in_cache_from_location_ARG_it_was_successfully_resolved_to_ARG = DiagnosticMessage{
    .message = "Reusing resolution of type reference directive '{0s}' from '{1s}' found in cache from location '{2s}', it was successfully resolved to '{3s}'.",
    .category = "Message",
    .code = "6396",
};
pub const reusing_resolution_of_type_reference_directive_ARG_from_ARG_found_in_cache_from_location_ARG_it_was_successfully_resolved_to_ARG_with_package_id_ARG = DiagnosticMessage{
    .message = "Reusing resolution of type reference directive '{0s}' from '{1s}' found in cache from location '{2s}', it was successfully resolved to '{3s}' with Package ID '{4s}'.",
    .category = "Message",
    .code = "6397",
};
pub const reusing_resolution_of_type_reference_directive_ARG_from_ARG_found_in_cache_from_location_ARG_it_was_not_resolved = DiagnosticMessage{
    .message = "Reusing resolution of type reference directive '{0s}' from '{1s}' found in cache from location '{2s}', it was not resolved.",
    .category = "Message",
    .code = "6398",
};
pub const project_ARG_is_out_of_date_because_buildinfo_file_ARG_indicates_that_some_of_the_changes_were_not_emitted = DiagnosticMessage{
    .message = "Project '{0s}' is out of date because buildinfo file '{1s}' indicates that some of the changes were not emitted",
    .category = "Message",
    .code = "6399",
};
pub const project_ARG_is_up_to_date_but_needs_to_update_timestamps_of_output_files_that_are_older_than_input_files = DiagnosticMessage{
    .message = "Project '{0s}' is up to date but needs to update timestamps of output files that are older than input files",
    .category = "Message",
    .code = "6400",
};
pub const project_ARG_is_out_of_date_because_there_was_error_reading_file_ARG = DiagnosticMessage{
    .message = "Project '{0s}' is out of date because there was error reading file '{1s}'",
    .category = "Message",
    .code = "6401",
};
pub const resolving_in_ARG_mode_with_conditions_ARG = DiagnosticMessage{
    .message = "Resolving in {0s} mode with conditions {1s}.",
    .category = "Message",
    .code = "6402",
};
pub const matched_ARG_condition_ARG = DiagnosticMessage{
    .message = "Matched '{0s}' condition '{1s}'.",
    .category = "Message",
    .code = "6403",
};
pub const using_ARG_subpath_ARG_with_target_ARG = DiagnosticMessage{
    .message = "Using '{0s}' subpath '{1s}' with target '{2s}'.",
    .category = "Message",
    .code = "6404",
};
pub const saw_non_matching_condition_ARG = DiagnosticMessage{
    .message = "Saw non-matching condition '{0s}'.",
    .category = "Message",
    .code = "6405",
};
pub const project_ARG_is_out_of_date_because_buildinfo_file_ARG_indicates_there_is_change_in_compileroptions = DiagnosticMessage{
    .message = "Project '{0s}' is out of date because buildinfo file '{1s}' indicates there is change in compilerOptions",
    .category = "Message",
    .code = "6406",
};
pub const allow_imports_to_include_typescript_file_extensions_requires_moduleresolution_bundler_and_either_noemit_or_emitdeclarationonly_to_be_set = DiagnosticMessage{
    .message = "Allow imports to include TypeScript file extensions. Requires '--moduleResolution bundler' and either '--noEmit' or '--emitDeclarationOnly' to be set.",
    .category = "Message",
    .code = "6407",
};
pub const use_the_package_json_exports_field_when_resolving_package_imports = DiagnosticMessage{
    .message = "Use the package.json 'exports' field when resolving package imports.",
    .category = "Message",
    .code = "6408",
};
pub const use_the_package_json_imports_field_when_resolving_imports = DiagnosticMessage{
    .message = "Use the package.json 'imports' field when resolving imports.",
    .category = "Message",
    .code = "6409",
};
pub const conditions_to_set_in_addition_to_the_resolver_specific_defaults_when_resolving_imports = DiagnosticMessage{
    .message = "Conditions to set in addition to the resolver-specific defaults when resolving imports.",
    .category = "Message",
    .code = "6410",
};
pub const true_when_moduleresolution_is_node16_nodenext_or_bundler_otherwise_false = DiagnosticMessage{
    .message = "`true` when 'moduleResolution' is 'node16', 'nodenext', or 'bundler'; otherwise `false`.",
    .category = "Message",
    .code = "6411",
};
pub const project_ARG_is_out_of_date_because_buildinfo_file_ARG_indicates_that_file_ARG_was_root_file_of_compilation_but_not_any_more = DiagnosticMessage{
    .message = "Project '{0s}' is out of date because buildinfo file '{1s}' indicates that file '{2s}' was root file of compilation but not any more.",
    .category = "Message",
    .code = "6412",
};
pub const entering_conditional_exports = DiagnosticMessage{
    .message = "Entering conditional exports.",
    .category = "Message",
    .code = "6413",
};
pub const resolved_under_condition_ARG = DiagnosticMessage{
    .message = "Resolved under condition '{0s}'.",
    .category = "Message",
    .code = "6414",
};
pub const failed_to_resolve_under_condition_ARG = DiagnosticMessage{
    .message = "Failed to resolve under condition '{0s}'.",
    .category = "Message",
    .code = "6415",
};
pub const exiting_conditional_exports = DiagnosticMessage{
    .message = "Exiting conditional exports.",
    .category = "Message",
    .code = "6416",
};
pub const searching_all_ancestor_node_modules_directories_for_preferred_extensions_ARG = DiagnosticMessage{
    .message = "Searching all ancestor node_modules directories for preferred extensions: {0s}.",
    .category = "Message",
    .code = "6417",
};
pub const searching_all_ancestor_node_modules_directories_for_fallback_extensions_ARG = DiagnosticMessage{
    .message = "Searching all ancestor node_modules directories for fallback extensions: {0s}.",
    .category = "Message",
    .code = "6418",
};
pub const the_expected_type_comes_from_property_ARG_which_is_declared_here_on_type_ARG = DiagnosticMessage{
    .message = "The expected type comes from property '{0s}' which is declared here on type '{1s}'",
    .category = "Message",
    .code = "6500",
};
pub const the_expected_type_comes_from_this_index_signature = DiagnosticMessage{
    .message = "The expected type comes from this index signature.",
    .category = "Message",
    .code = "6501",
};
pub const the_expected_type_comes_from_the_return_type_of_this_signature = DiagnosticMessage{
    .message = "The expected type comes from the return type of this signature.",
    .category = "Message",
    .code = "6502",
};
pub const print_names_of_files_that_are_part_of_the_compilation_and_then_stop_processing = DiagnosticMessage{
    .message = "Print names of files that are part of the compilation and then stop processing.",
    .category = "Message",
    .code = "6503",
};
pub const file_ARG_is_a_javascript_file_did_you_mean_to_enable_the_allowjs_option = DiagnosticMessage{
    .message = "File '{0s}' is a JavaScript file. Did you mean to enable the 'allowJs' option?",
    .category = "Error",
    .code = "6504",
};
pub const print_names_of_files_and_the_reason_they_are_part_of_the_compilation = DiagnosticMessage{
    .message = "Print names of files and the reason they are part of the compilation.",
    .category = "Message",
    .code = "6505",
};
pub const consider_adding_a_declare_modifier_to_this_class = DiagnosticMessage{
    .message = "Consider adding a 'declare' modifier to this class.",
    .category = "Message",
    .code = "6506",
};
pub const allow_javascript_files_to_be_a_part_of_your_program_use_the_checkjs_option_to_get_errors_from_these_files = DiagnosticMessage{
    .message = "Allow JavaScript files to be a part of your program. Use the 'checkJS' option to get errors from these files.",
    .category = "Message",
    .code = "6600",
};
pub const allow_import_x_from_y_when_a_module_doesn_t_have_a_default_export = DiagnosticMessage{
    .message = "Allow 'import x from y' when a module doesn't have a default export.",
    .category = "Message",
    .code = "6601",
};
pub const allow_accessing_umd_globals_from_modules = DiagnosticMessage{
    .message = "Allow accessing UMD globals from modules.",
    .category = "Message",
    .code = "6602",
};
pub const disable_error_reporting_for_unreachable_code = DiagnosticMessage{
    .message = "Disable error reporting for unreachable code.",
    .category = "Message",
    .code = "6603",
};
pub const disable_error_reporting_for_unused_labels = DiagnosticMessage{
    .message = "Disable error reporting for unused labels.",
    .category = "Message",
    .code = "6604",
};
pub const ensure_use_strict_is_always_emitted = DiagnosticMessage{
    .message = "Ensure 'use strict' is always emitted.",
    .category = "Message",
    .code = "6605",
};
pub const have_recompiles_in_projects_that_use_incremental_and_watch_mode_assume_that_changes_within_a_file_will_only_affect_files_directly_depending_on_it = DiagnosticMessage{
    .message = "Have recompiles in projects that use 'incremental' and 'watch' mode assume that changes within a file will only affect files directly depending on it.",
    .category = "Message",
    .code = "6606",
};
pub const specify_the_base_directory_to_resolve_non_relative_module_names = DiagnosticMessage{
    .message = "Specify the base directory to resolve non-relative module names.",
    .category = "Message",
    .code = "6607",
};
pub const no_longer_supported_in_early_versions_manually_set_the_text_encoding_for_reading_files = DiagnosticMessage{
    .message = "No longer supported. In early versions, manually set the text encoding for reading files.",
    .category = "Message",
    .code = "6608",
};
pub const enable_error_reporting_in_type_checked_javascript_files = DiagnosticMessage{
    .message = "Enable error reporting in type-checked JavaScript files.",
    .category = "Message",
    .code = "6609",
};
pub const enable_constraints_that_allow_a_typescript_project_to_be_used_with_project_references = DiagnosticMessage{
    .message = "Enable constraints that allow a TypeScript project to be used with project references.",
    .category = "Message",
    .code = "6611",
};
pub const generate_d_ts_files_from_typescript_and_javascript_files_in_your_project = DiagnosticMessage{
    .message = "Generate .d.ts files from TypeScript and JavaScript files in your project.",
    .category = "Message",
    .code = "6612",
};
pub const specify_the_output_directory_for_generated_declaration_files = DiagnosticMessage{
    .message = "Specify the output directory for generated declaration files.",
    .category = "Message",
    .code = "6613",
};
pub const create_sourcemaps_for_d_ts_files = DiagnosticMessage{
    .message = "Create sourcemaps for d.ts files.",
    .category = "Message",
    .code = "6614",
};
pub const output_compiler_performance_information_after_building = DiagnosticMessage{
    .message = "Output compiler performance information after building.",
    .category = "Message",
    .code = "6615",
};
pub const disables_inference_for_type_acquisition_by_looking_at_filenames_in_a_project = DiagnosticMessage{
    .message = "Disables inference for type acquisition by looking at filenames in a project.",
    .category = "Message",
    .code = "6616",
};
pub const reduce_the_number_of_projects_loaded_automatically_by_typescript = DiagnosticMessage{
    .message = "Reduce the number of projects loaded automatically by TypeScript.",
    .category = "Message",
    .code = "6617",
};
pub const remove_the_20mb_cap_on_total_source_code_size_for_javascript_files_in_the_typescript_language_server = DiagnosticMessage{
    .message = "Remove the 20mb cap on total source code size for JavaScript files in the TypeScript language server.",
    .category = "Message",
    .code = "6618",
};
pub const opt_a_project_out_of_multi_project_reference_checking_when_editing = DiagnosticMessage{
    .message = "Opt a project out of multi-project reference checking when editing.",
    .category = "Message",
    .code = "6619",
};
pub const disable_preferring_source_files_instead_of_declaration_files_when_referencing_composite_projects = DiagnosticMessage{
    .message = "Disable preferring source files instead of declaration files when referencing composite projects.",
    .category = "Message",
    .code = "6620",
};
pub const emit_more_compliant_but_verbose_and_less_performant_javascript_for_iteration = DiagnosticMessage{
    .message = "Emit more compliant, but verbose and less performant JavaScript for iteration.",
    .category = "Message",
    .code = "6621",
};
pub const emit_a_utf_8_byte_order_mark_bom_in_the_beginning_of_output_files = DiagnosticMessage{
    .message = "Emit a UTF-8 Byte Order Mark (BOM) in the beginning of output files.",
    .category = "Message",
    .code = "6622",
};
pub const only_output_d_ts_files_and_not_javascript_files = DiagnosticMessage{
    .message = "Only output d.ts files and not JavaScript files.",
    .category = "Message",
    .code = "6623",
};
pub const emit_design_type_metadata_for_decorated_declarations_in_source_files = DiagnosticMessage{
    .message = "Emit design-type metadata for decorated declarations in source files.",
    .category = "Message",
    .code = "6624",
};
pub const disable_the_type_acquisition_for_javascript_projects = DiagnosticMessage{
    .message = "Disable the type acquisition for JavaScript projects",
    .category = "Message",
    .code = "6625",
};
pub const emit_additional_javascript_to_ease_support_for_importing_commonjs_modules_this_enables_allowsyntheticdefaultimports_for_type_compatibility = DiagnosticMessage{
    .message = "Emit additional JavaScript to ease support for importing CommonJS modules. This enables 'allowSyntheticDefaultImports' for type compatibility.",
    .category = "Message",
    .code = "6626",
};
pub const filters_results_from_the_include_option = DiagnosticMessage{
    .message = "Filters results from the `include` option.",
    .category = "Message",
    .code = "6627",
};
pub const remove_a_list_of_directories_from_the_watch_process = DiagnosticMessage{
    .message = "Remove a list of directories from the watch process.",
    .category = "Message",
    .code = "6628",
};
pub const remove_a_list_of_files_from_the_watch_mode_s_processing = DiagnosticMessage{
    .message = "Remove a list of files from the watch mode's processing.",
    .category = "Message",
    .code = "6629",
};
pub const enable_experimental_support_for_legacy_experimental_decorators = DiagnosticMessage{
    .message = "Enable experimental support for legacy experimental decorators.",
    .category = "Message",
    .code = "6630",
};
pub const print_files_read_during_the_compilation_including_why_it_was_included = DiagnosticMessage{
    .message = "Print files read during the compilation including why it was included.",
    .category = "Message",
    .code = "6631",
};
pub const output_more_detailed_compiler_performance_information_after_building = DiagnosticMessage{
    .message = "Output more detailed compiler performance information after building.",
    .category = "Message",
    .code = "6632",
};
pub const specify_one_or_more_path_or_node_module_references_to_base_configuration_files_from_which_settings_are_inherited = DiagnosticMessage{
    .message = "Specify one or more path or node module references to base configuration files from which settings are inherited.",
    .category = "Message",
    .code = "6633",
};
pub const specify_what_approach_the_watcher_should_use_if_the_system_runs_out_of_native_file_watchers = DiagnosticMessage{
    .message = "Specify what approach the watcher should use if the system runs out of native file watchers.",
    .category = "Message",
    .code = "6634",
};
pub const include_a_list_of_files_this_does_not_support_glob_patterns_as_opposed_to_include = DiagnosticMessage{
    .message = "Include a list of files. This does not support glob patterns, as opposed to `include`.",
    .category = "Message",
    .code = "6635",
};
pub const build_all_projects_including_those_that_appear_to_be_up_to_date = DiagnosticMessage{
    .message = "Build all projects, including those that appear to be up to date.",
    .category = "Message",
    .code = "6636",
};
pub const ensure_that_casing_is_correct_in_imports = DiagnosticMessage{
    .message = "Ensure that casing is correct in imports.",
    .category = "Message",
    .code = "6637",
};
pub const emit_a_v8_cpu_profile_of_the_compiler_run_for_debugging = DiagnosticMessage{
    .message = "Emit a v8 CPU profile of the compiler run for debugging.",
    .category = "Message",
    .code = "6638",
};
pub const allow_importing_helper_functions_from_tslib_once_per_project_instead_of_including_them_per_file = DiagnosticMessage{
    .message = "Allow importing helper functions from tslib once per project, instead of including them per-file.",
    .category = "Message",
    .code = "6639",
};
pub const specify_a_list_of_glob_patterns_that_match_files_to_be_included_in_compilation = DiagnosticMessage{
    .message = "Specify a list of glob patterns that match files to be included in compilation.",
    .category = "Message",
    .code = "6641",
};
pub const save_tsbuildinfo_files_to_allow_for_incremental_compilation_of_projects = DiagnosticMessage{
    .message = "Save .tsbuildinfo files to allow for incremental compilation of projects.",
    .category = "Message",
    .code = "6642",
};
pub const include_sourcemap_files_inside_the_emitted_javascript = DiagnosticMessage{
    .message = "Include sourcemap files inside the emitted JavaScript.",
    .category = "Message",
    .code = "6643",
};
pub const include_source_code_in_the_sourcemaps_inside_the_emitted_javascript = DiagnosticMessage{
    .message = "Include source code in the sourcemaps inside the emitted JavaScript.",
    .category = "Message",
    .code = "6644",
};
pub const ensure_that_each_file_can_be_safely_transpiled_without_relying_on_other_imports = DiagnosticMessage{
    .message = "Ensure that each file can be safely transpiled without relying on other imports.",
    .category = "Message",
    .code = "6645",
};
pub const specify_what_jsx_code_is_generated = DiagnosticMessage{
    .message = "Specify what JSX code is generated.",
    .category = "Message",
    .code = "6646",
};
pub const specify_the_jsx_factory_function_used_when_targeting_react_jsx_emit_e_g_react_createelement_or_h = DiagnosticMessage{
    .message = "Specify the JSX factory function used when targeting React JSX emit, e.g. 'React.createElement' or 'h'.",
    .category = "Message",
    .code = "6647",
};
pub const specify_the_jsx_fragment_reference_used_for_fragments_when_targeting_react_jsx_emit_e_g_react_fragment_or_fragment = DiagnosticMessage{
    .message = "Specify the JSX Fragment reference used for fragments when targeting React JSX emit e.g. 'React.Fragment' or 'Fragment'.",
    .category = "Message",
    .code = "6648",
};
pub const specify_module_specifier_used_to_import_the_jsx_factory_functions_when_using_jsx_react_jsx = DiagnosticMessage{
    .message = "Specify module specifier used to import the JSX factory functions when using 'jsx: react-jsx*'.",
    .category = "Message",
    .code = "6649",
};
pub const make_keyof_only_return_strings_instead_of_string_numbers_or_symbols_legacy_option = DiagnosticMessage{
    .message = "Make keyof only return strings instead of string, numbers or symbols. Legacy option.",
    .category = "Message",
    .code = "6650",
};
pub const specify_a_set_of_bundled_library_declaration_files_that_describe_the_target_runtime_environment = DiagnosticMessage{
    .message = "Specify a set of bundled library declaration files that describe the target runtime environment.",
    .category = "Message",
    .code = "6651",
};
pub const print_the_names_of_emitted_files_after_a_compilation = DiagnosticMessage{
    .message = "Print the names of emitted files after a compilation.",
    .category = "Message",
    .code = "6652",
};
pub const print_all_of_the_files_read_during_the_compilation = DiagnosticMessage{
    .message = "Print all of the files read during the compilation.",
    .category = "Message",
    .code = "6653",
};
pub const set_the_language_of_the_messaging_from_typescript_this_does_not_affect_emit = DiagnosticMessage{
    .message = "Set the language of the messaging from TypeScript. This does not affect emit.",
    .category = "Message",
    .code = "6654",
};
pub const specify_the_location_where_debugger_should_locate_map_files_instead_of_generated_locations = DiagnosticMessage{
    .message = "Specify the location where debugger should locate map files instead of generated locations.",
    .category = "Message",
    .code = "6655",
};
pub const specify_the_maximum_folder_depth_used_for_checking_javascript_files_from_node_modules_only_applicable_with_allowjs = DiagnosticMessage{
    .message = "Specify the maximum folder depth used for checking JavaScript files from 'node_modules'. Only applicable with 'allowJs'.",
    .category = "Message",
    .code = "6656",
};
pub const specify_what_module_code_is_generated = DiagnosticMessage{
    .message = "Specify what module code is generated.",
    .category = "Message",
    .code = "6657",
};
pub const specify_how_typescript_looks_up_a_file_from_a_given_module_specifier = DiagnosticMessage{
    .message = "Specify how TypeScript looks up a file from a given module specifier.",
    .category = "Message",
    .code = "6658",
};
pub const set_the_newline_character_for_emitting_files = DiagnosticMessage{
    .message = "Set the newline character for emitting files.",
    .category = "Message",
    .code = "6659",
};
pub const disable_emitting_files_from_a_compilation = DiagnosticMessage{
    .message = "Disable emitting files from a compilation.",
    .category = "Message",
    .code = "6660",
};
pub const disable_generating_custom_helper_functions_like_extends_in_compiled_output = DiagnosticMessage{
    .message = "Disable generating custom helper functions like '__extends' in compiled output.",
    .category = "Message",
    .code = "6661",
};
pub const disable_emitting_files_if_any_type_checking_errors_are_reported = DiagnosticMessage{
    .message = "Disable emitting files if any type checking errors are reported.",
    .category = "Message",
    .code = "6662",
};
pub const disable_truncating_types_in_error_messages = DiagnosticMessage{
    .message = "Disable truncating types in error messages.",
    .category = "Message",
    .code = "6663",
};
pub const enable_error_reporting_for_fallthrough_cases_in_switch_statements = DiagnosticMessage{
    .message = "Enable error reporting for fallthrough cases in switch statements.",
    .category = "Message",
    .code = "6664",
};
pub const enable_error_reporting_for_expressions_and_declarations_with_an_implied_any_type = DiagnosticMessage{
    .message = "Enable error reporting for expressions and declarations with an implied 'any' type.",
    .category = "Message",
    .code = "6665",
};
pub const ensure_overriding_members_in_derived_classes_are_marked_with_an_override_modifier = DiagnosticMessage{
    .message = "Ensure overriding members in derived classes are marked with an override modifier.",
    .category = "Message",
    .code = "6666",
};
pub const enable_error_reporting_for_codepaths_that_do_not_explicitly_return_in_a_function = DiagnosticMessage{
    .message = "Enable error reporting for codepaths that do not explicitly return in a function.",
    .category = "Message",
    .code = "6667",
};
pub const enable_error_reporting_when_this_is_given_the_type_any = DiagnosticMessage{
    .message = "Enable error reporting when 'this' is given the type 'any'.",
    .category = "Message",
    .code = "6668",
};
pub const disable_adding_use_strict_directives_in_emitted_javascript_files = DiagnosticMessage{
    .message = "Disable adding 'use strict' directives in emitted JavaScript files.",
    .category = "Message",
    .code = "6669",
};
pub const disable_including_any_library_files_including_the_default_lib_d_ts = DiagnosticMessage{
    .message = "Disable including any library files, including the default lib.d.ts.",
    .category = "Message",
    .code = "6670",
};
pub const enforces_using_indexed_accessors_for_keys_declared_using_an_indexed_type = DiagnosticMessage{
    .message = "Enforces using indexed accessors for keys declared using an indexed type.",
    .category = "Message",
    .code = "6671",
};
pub const disallow_import_s_require_s_or_reference_s_from_expanding_the_number_of_files_typescript_should_add_to_a_project = DiagnosticMessage{
    .message = "Disallow 'import's, 'require's or '<reference>'s from expanding the number of files TypeScript should add to a project.",
    .category = "Message",
    .code = "6672",
};
pub const disable_strict_checking_of_generic_signatures_in_function_types = DiagnosticMessage{
    .message = "Disable strict checking of generic signatures in function types.",
    .category = "Message",
    .code = "6673",
};
pub const add_undefined_to_a_type_when_accessed_using_an_index = DiagnosticMessage{
    .message = "Add 'undefined' to a type when accessed using an index.",
    .category = "Message",
    .code = "6674",
};
pub const enable_error_reporting_when_local_variables_aren_t_read = DiagnosticMessage{
    .message = "Enable error reporting when local variables aren't read.",
    .category = "Message",
    .code = "6675",
};
pub const raise_an_error_when_a_function_parameter_isn_t_read = DiagnosticMessage{
    .message = "Raise an error when a function parameter isn't read.",
    .category = "Message",
    .code = "6676",
};
pub const deprecated_setting_use_outfile_instead = DiagnosticMessage{
    .message = "Deprecated setting. Use 'outFile' instead.",
    .category = "Message",
    .code = "6677",
};
pub const specify_an_output_folder_for_all_emitted_files = DiagnosticMessage{
    .message = "Specify an output folder for all emitted files.",
    .category = "Message",
    .code = "6678",
};
pub const specify_a_file_that_bundles_all_outputs_into_one_javascript_file_if_declaration_is_true_also_designates_a_file_that_bundles_all_d_ts_output = DiagnosticMessage{
    .message = "Specify a file that bundles all outputs into one JavaScript file. If 'declaration' is true, also designates a file that bundles all .d.ts output.",
    .category = "Message",
    .code = "6679",
};
pub const specify_a_set_of_entries_that_re_map_imports_to_additional_lookup_locations = DiagnosticMessage{
    .message = "Specify a set of entries that re-map imports to additional lookup locations.",
    .category = "Message",
    .code = "6680",
};
pub const specify_a_list_of_language_service_plugins_to_include = DiagnosticMessage{
    .message = "Specify a list of language service plugins to include.",
    .category = "Message",
    .code = "6681",
};
pub const disable_erasing_const_enum_declarations_in_generated_code = DiagnosticMessage{
    .message = "Disable erasing 'const enum' declarations in generated code.",
    .category = "Message",
    .code = "6682",
};
pub const disable_resolving_symlinks_to_their_realpath_this_correlates_to_the_same_flag_in_node = DiagnosticMessage{
    .message = "Disable resolving symlinks to their realpath. This correlates to the same flag in node.",
    .category = "Message",
    .code = "6683",
};
pub const disable_wiping_the_console_in_watch_mode = DiagnosticMessage{
    .message = "Disable wiping the console in watch mode.",
    .category = "Message",
    .code = "6684",
};
pub const enable_color_and_formatting_in_typescript_s_output_to_make_compiler_errors_easier_to_read = DiagnosticMessage{
    .message = "Enable color and formatting in TypeScript's output to make compiler errors easier to read.",
    .category = "Message",
    .code = "6685",
};
pub const specify_the_object_invoked_for_createelement_this_only_applies_when_targeting_react_jsx_emit = DiagnosticMessage{
    .message = "Specify the object invoked for 'createElement'. This only applies when targeting 'react' JSX emit.",
    .category = "Message",
    .code = "6686",
};
pub const specify_an_array_of_objects_that_specify_paths_for_projects_used_in_project_references = DiagnosticMessage{
    .message = "Specify an array of objects that specify paths for projects. Used in project references.",
    .category = "Message",
    .code = "6687",
};
pub const disable_emitting_comments = DiagnosticMessage{
    .message = "Disable emitting comments.",
    .category = "Message",
    .code = "6688",
};
pub const enable_importing_json_files = DiagnosticMessage{
    .message = "Enable importing .json files.",
    .category = "Message",
    .code = "6689",
};
pub const specify_the_root_folder_within_your_source_files = DiagnosticMessage{
    .message = "Specify the root folder within your source files.",
    .category = "Message",
    .code = "6690",
};
pub const allow_multiple_folders_to_be_treated_as_one_when_resolving_modules = DiagnosticMessage{
    .message = "Allow multiple folders to be treated as one when resolving modules.",
    .category = "Message",
    .code = "6691",
};
pub const skip_type_checking_d_ts_files_that_are_included_with_typescript = DiagnosticMessage{
    .message = "Skip type checking .d.ts files that are included with TypeScript.",
    .category = "Message",
    .code = "6692",
};
pub const skip_type_checking_all_d_ts_files = DiagnosticMessage{
    .message = "Skip type checking all .d.ts files.",
    .category = "Message",
    .code = "6693",
};
pub const create_source_map_files_for_emitted_javascript_files = DiagnosticMessage{
    .message = "Create source map files for emitted JavaScript files.",
    .category = "Message",
    .code = "6694",
};
pub const specify_the_root_path_for_debuggers_to_find_the_reference_source_code = DiagnosticMessage{
    .message = "Specify the root path for debuggers to find the reference source code.",
    .category = "Message",
    .code = "6695",
};
pub const check_that_the_arguments_for_bind_call_and_apply_methods_match_the_original_function = DiagnosticMessage{
    .message = "Check that the arguments for 'bind', 'call', and 'apply' methods match the original function.",
    .category = "Message",
    .code = "6697",
};
pub const when_assigning_functions_check_to_ensure_parameters_and_the_return_values_are_subtype_compatible = DiagnosticMessage{
    .message = "When assigning functions, check to ensure parameters and the return values are subtype-compatible.",
    .category = "Message",
    .code = "6698",
};
pub const when_type_checking_take_into_account_null_and_undefined = DiagnosticMessage{
    .message = "When type checking, take into account 'null' and 'undefined'.",
    .category = "Message",
    .code = "6699",
};
pub const check_for_class_properties_that_are_declared_but_not_set_in_the_constructor = DiagnosticMessage{
    .message = "Check for class properties that are declared but not set in the constructor.",
    .category = "Message",
    .code = "6700",
};
pub const disable_emitting_declarations_that_have_internal_in_their_jsdoc_comments = DiagnosticMessage{
    .message = "Disable emitting declarations that have '@internal' in their JSDoc comments.",
    .category = "Message",
    .code = "6701",
};
pub const disable_reporting_of_excess_property_errors_during_the_creation_of_object_literals = DiagnosticMessage{
    .message = "Disable reporting of excess property errors during the creation of object literals.",
    .category = "Message",
    .code = "6702",
};
pub const suppress_noimplicitany_errors_when_indexing_objects_that_lack_index_signatures = DiagnosticMessage{
    .message = "Suppress 'noImplicitAny' errors when indexing objects that lack index signatures.",
    .category = "Message",
    .code = "6703",
};
pub const synchronously_call_callbacks_and_update_the_state_of_directory_watchers_on_platforms_that_don_t_support_recursive_watching_natively = DiagnosticMessage{
    .message = "Synchronously call callbacks and update the state of directory watchers on platforms that don`t support recursive watching natively.",
    .category = "Message",
    .code = "6704",
};
pub const set_the_javascript_language_version_for_emitted_javascript_and_include_compatible_library_declarations = DiagnosticMessage{
    .message = "Set the JavaScript language version for emitted JavaScript and include compatible library declarations.",
    .category = "Message",
    .code = "6705",
};
pub const log_paths_used_during_the_moduleresolution_process = DiagnosticMessage{
    .message = "Log paths used during the 'moduleResolution' process.",
    .category = "Message",
    .code = "6706",
};
pub const specify_the_path_to_tsbuildinfo_incremental_compilation_file = DiagnosticMessage{
    .message = "Specify the path to .tsbuildinfo incremental compilation file.",
    .category = "Message",
    .code = "6707",
};
pub const specify_options_for_automatic_acquisition_of_declaration_files = DiagnosticMessage{
    .message = "Specify options for automatic acquisition of declaration files.",
    .category = "Message",
    .code = "6709",
};
pub const specify_multiple_folders_that_act_like_node_modules_types = DiagnosticMessage{
    .message = "Specify multiple folders that act like './node_modules/@types'.",
    .category = "Message",
    .code = "6710",
};
pub const specify_type_package_names_to_be_included_without_being_referenced_in_a_source_file = DiagnosticMessage{
    .message = "Specify type package names to be included without being referenced in a source file.",
    .category = "Message",
    .code = "6711",
};
pub const emit_ecmascript_standard_compliant_class_fields = DiagnosticMessage{
    .message = "Emit ECMAScript-standard-compliant class fields.",
    .category = "Message",
    .code = "6712",
};
pub const enable_verbose_logging = DiagnosticMessage{
    .message = "Enable verbose logging.",
    .category = "Message",
    .code = "6713",
};
pub const specify_how_directories_are_watched_on_systems_that_lack_recursive_file_watching_functionality = DiagnosticMessage{
    .message = "Specify how directories are watched on systems that lack recursive file-watching functionality.",
    .category = "Message",
    .code = "6714",
};
pub const specify_how_the_typescript_watch_mode_works = DiagnosticMessage{
    .message = "Specify how the TypeScript watch mode works.",
    .category = "Message",
    .code = "6715",
};
pub const require_undeclared_properties_from_index_signatures_to_use_element_accesses = DiagnosticMessage{
    .message = "Require undeclared properties from index signatures to use element accesses.",
    .category = "Message",
    .code = "6717",
};
pub const specify_emit_checking_behavior_for_imports_that_are_only_used_for_types = DiagnosticMessage{
    .message = "Specify emit/checking behavior for imports that are only used for types.",
    .category = "Message",
    .code = "6718",
};
pub const require_sufficient_annotation_on_exports_so_other_tools_can_trivially_generate_declaration_files = DiagnosticMessage{
    .message = "Require sufficient annotation on exports so other tools can trivially generate declaration files.",
    .category = "Message",
    .code = "6719",
};
pub const default_catch_clause_variables_as_unknown_instead_of_any = DiagnosticMessage{
    .message = "Default catch clause variables as 'unknown' instead of 'any'.",
    .category = "Message",
    .code = "6803",
};
pub const do_not_transform_or_elide_any_imports_or_exports_not_marked_as_type_only_ensuring_they_are_written_in_the_output_file_s_format_based_on_the_module_setting = DiagnosticMessage{
    .message = "Do not transform or elide any imports or exports not marked as type-only, ensuring they are written in the output file's format based on the 'module' setting.",
    .category = "Message",
    .code = "6804",
};
pub const disable_full_type_checking_only_critical_parse_and_emit_errors_will_be_reported = DiagnosticMessage{
    .message = "Disable full type checking (only critical parse and emit errors will be reported).",
    .category = "Message",
    .code = "6805",
};
pub const one_of = DiagnosticMessage{
    .message = "one of:",
    .category = "Message",
    .code = "6900",
};
pub const one_or_more = DiagnosticMessage{
    .message = "one or more:",
    .category = "Message",
    .code = "6901",
};
pub const type_1 = DiagnosticMessage{
    .message = "type:",
    .category = "Message",
    .code = "6902",
};
pub const default = DiagnosticMessage{
    .message = "default:",
    .category = "Message",
    .code = "6903",
};
pub const module_system_or_esmoduleinterop = DiagnosticMessage{
    .message = "module === \"system\" or esModuleInterop",
    .category = "Message",
    .code = "6904",
};
pub const false_unless_strict_is_set = DiagnosticMessage{
    .message = "`false`, unless `strict` is set",
    .category = "Message",
    .code = "6905",
};
pub const false_unless_composite_is_set = DiagnosticMessage{
    .message = "`false`, unless `composite` is set",
    .category = "Message",
    .code = "6906",
};
pub const node_modules_bower_components_jspm_packages_plus_the_value_of_outdir_if_one_is_specified = DiagnosticMessage{
    .message = "`[\"node_modules\", \"bower_components\", \"jspm_packages\"]`, plus the value of `outDir` if one is specified.",
    .category = "Message",
    .code = "6907",
};
pub const if_files_is_specified_otherwise = DiagnosticMessage{
    .message = "`[]` if `files` is specified, otherwise `[\"**/*\"]`",
    .category = "Message",
    .code = "6908",
};
pub const true_if_composite_false_otherwise = DiagnosticMessage{
    .message = "`true` if `composite`, `false` otherwise",
    .category = "Message",
    .code = "6909",
};
pub const module_amd_or_umd_or_system_or_es6_then_classic_otherwise_node = DiagnosticMessage{
    .message = "module === `AMD` or `UMD` or `System` or `ES6`, then `Classic`, Otherwise `Node`",
    .category = "Message",
    .code = "69010",
};
pub const computed_from_the_list_of_input_files = DiagnosticMessage{
    .message = "Computed from the list of input files",
    .category = "Message",
    .code = "6911",
};
pub const platform_specific = DiagnosticMessage{
    .message = "Platform specific",
    .category = "Message",
    .code = "6912",
};
pub const you_can_learn_about_all_of_the_compiler_options_at_ARG = DiagnosticMessage{
    .message = "You can learn about all of the compiler options at {0s}",
    .category = "Message",
    .code = "6913",
};
pub const including_watch_w_will_start_watching_the_current_project_for_the_file_changes_once_set_you_can_config_watch_mode_with = DiagnosticMessage{
    .message = "Including --watch, -w will start watching the current project for the file changes. Once set, you can config watch mode with:",
    .category = "Message",
    .code = "6914",
};
pub const using_build_b_will_make_tsc_behave_more_like_a_build_orchestrator_than_a_compiler_this_is_used_to_trigger_building_composite_projects_which_you_can_learn_more_about_at_ARG = DiagnosticMessage{
    .message = "Using --build, -b will make tsc behave more like a build orchestrator than a compiler. This is used to trigger building composite projects which you can learn more about at {0s}",
    .category = "Message",
    .code = "6915",
};
pub const common_commands = DiagnosticMessage{
    .message = "COMMON COMMANDS",
    .category = "Message",
    .code = "6916",
};
pub const all_compiler_options = DiagnosticMessage{
    .message = "ALL COMPILER OPTIONS",
    .category = "Message",
    .code = "6917",
};
pub const watch_options = DiagnosticMessage{
    .message = "WATCH OPTIONS",
    .category = "Message",
    .code = "6918",
};
pub const build_options = DiagnosticMessage{
    .message = "BUILD OPTIONS",
    .category = "Message",
    .code = "6919",
};
pub const common_compiler_options = DiagnosticMessage{
    .message = "COMMON COMPILER OPTIONS",
    .category = "Message",
    .code = "6920",
};
pub const command_line_flags = DiagnosticMessage{
    .message = "COMMAND LINE FLAGS",
    .category = "Message",
    .code = "6921",
};
pub const tsc_the_typescript_compiler = DiagnosticMessage{
    .message = "tsc: The TypeScript Compiler",
    .category = "Message",
    .code = "6922",
};
pub const compiles_the_current_project_tsconfig_json_in_the_working_directory = DiagnosticMessage{
    .message = "Compiles the current project (tsconfig.json in the working directory.)",
    .category = "Message",
    .code = "6923",
};
pub const ignoring_tsconfig_json_compiles_the_specified_files_with_default_compiler_options = DiagnosticMessage{
    .message = "Ignoring tsconfig.json, compiles the specified files with default compiler options.",
    .category = "Message",
    .code = "6924",
};
pub const build_a_composite_project_in_the_working_directory = DiagnosticMessage{
    .message = "Build a composite project in the working directory.",
    .category = "Message",
    .code = "6925",
};
pub const creates_a_tsconfig_json_with_the_recommended_settings_in_the_working_directory = DiagnosticMessage{
    .message = "Creates a tsconfig.json with the recommended settings in the working directory.",
    .category = "Message",
    .code = "6926",
};
pub const compiles_the_typescript_project_located_at_the_specified_path = DiagnosticMessage{
    .message = "Compiles the TypeScript project located at the specified path.",
    .category = "Message",
    .code = "6927",
};
pub const an_expanded_version_of_this_information_showing_all_possible_compiler_options = DiagnosticMessage{
    .message = "An expanded version of this information, showing all possible compiler options",
    .category = "Message",
    .code = "6928",
};
pub const compiles_the_current_project_with_additional_settings = DiagnosticMessage{
    .message = "Compiles the current project, with additional settings.",
    .category = "Message",
    .code = "6929",
};
pub const true_for_es2022_and_above_including_esnext = DiagnosticMessage{
    .message = "`true` for ES2022 and above, including ESNext.",
    .category = "Message",
    .code = "6930",
};
pub const list_of_file_name_suffixes_to_search_when_resolving_a_module = DiagnosticMessage{
    .message = "List of file name suffixes to search when resolving a module.",
    .category = "Error",
    .code = "6931",
};
pub const variable_ARG_implicitly_has_an_ARG_type = DiagnosticMessage{
    .message = "Variable '{0s}' implicitly has an '{1s}' type.",
    .category = "Error",
    .code = "7005",
};
pub const parameter_ARG_implicitly_has_an_ARG_type = DiagnosticMessage{
    .message = "Parameter '{0s}' implicitly has an '{1s}' type.",
    .category = "Error",
    .code = "7006",
};
pub const member_ARG_implicitly_has_an_ARG_type = DiagnosticMessage{
    .message = "Member '{0s}' implicitly has an '{1s}' type.",
    .category = "Error",
    .code = "7008",
};
pub const new_expression_whose_target_lacks_a_construct_signature_implicitly_has_an_any_type = DiagnosticMessage{
    .message = "'new' expression, whose target lacks a construct signature, implicitly has an 'any' type.",
    .category = "Error",
    .code = "7009",
};
pub const ARG_which_lacks_return_type_annotation_implicitly_has_an_ARG_return_type = DiagnosticMessage{
    .message = "'{0s}', which lacks return-type annotation, implicitly has an '{1s}' return type.",
    .category = "Error",
    .code = "7010",
};
pub const function_expression_which_lacks_return_type_annotation_implicitly_has_an_ARG_return_type = DiagnosticMessage{
    .message = "Function expression, which lacks return-type annotation, implicitly has an '{0s}' return type.",
    .category = "Error",
    .code = "7011",
};
pub const this_overload_implicitly_returns_the_type_ARG_because_it_lacks_a_return_type_annotation = DiagnosticMessage{
    .message = "This overload implicitly returns the type '{0s}' because it lacks a return type annotation.",
    .category = "Error",
    .code = "7012",
};
pub const construct_signature_which_lacks_return_type_annotation_implicitly_has_an_any_return_type = DiagnosticMessage{
    .message = "Construct signature, which lacks return-type annotation, implicitly has an 'any' return type.",
    .category = "Error",
    .code = "7013",
};
pub const function_type_which_lacks_return_type_annotation_implicitly_has_an_ARG_return_type = DiagnosticMessage{
    .message = "Function type, which lacks return-type annotation, implicitly has an '{0s}' return type.",
    .category = "Error",
    .code = "7014",
};
pub const element_implicitly_has_an_any_type_because_index_expression_is_not_of_type_number = DiagnosticMessage{
    .message = "Element implicitly has an 'any' type because index expression is not of type 'number'.",
    .category = "Error",
    .code = "7015",
};
pub const could_not_find_a_declaration_file_for_module_ARG_ARG_implicitly_has_an_any_type = DiagnosticMessage{
    .message = "Could not find a declaration file for module '{0s}'. '{1s}' implicitly has an 'any' type.",
    .category = "Error",
    .code = "7016",
};
pub const element_implicitly_has_an_any_type_because_type_ARG_has_no_index_signature = DiagnosticMessage{
    .message = "Element implicitly has an 'any' type because type '{0s}' has no index signature.",
    .category = "Error",
    .code = "7017",
};
pub const object_literal_s_property_ARG_implicitly_has_an_ARG_type = DiagnosticMessage{
    .message = "Object literal's property '{0s}' implicitly has an '{1s}' type.",
    .category = "Error",
    .code = "7018",
};
pub const rest_parameter_ARG_implicitly_has_an_any_type = DiagnosticMessage{
    .message = "Rest parameter '{0s}' implicitly has an 'any[]' type.",
    .category = "Error",
    .code = "7019",
};
pub const call_signature_which_lacks_return_type_annotation_implicitly_has_an_any_return_type = DiagnosticMessage{
    .message = "Call signature, which lacks return-type annotation, implicitly has an 'any' return type.",
    .category = "Error",
    .code = "7020",
};
pub const ARG_implicitly_has_type_any_because_it_does_not_have_a_type_annotation_and_is_referenced_directly_or_indirectly_in_its_own_initializer = DiagnosticMessage{
    .message = "'{0s}' implicitly has type 'any' because it does not have a type annotation and is referenced directly or indirectly in its own initializer.",
    .category = "Error",
    .code = "7022",
};
pub const ARG_implicitly_has_return_type_any_because_it_does_not_have_a_return_type_annotation_and_is_referenced_directly_or_indirectly_in_one_of_its_return_expressions = DiagnosticMessage{
    .message = "'{0s}' implicitly has return type 'any' because it does not have a return type annotation and is referenced directly or indirectly in one of its return expressions.",
    .category = "Error",
    .code = "7023",
};
pub const function_implicitly_has_return_type_any_because_it_does_not_have_a_return_type_annotation_and_is_referenced_directly_or_indirectly_in_one_of_its_return_expressions = DiagnosticMessage{
    .message = "Function implicitly has return type 'any' because it does not have a return type annotation and is referenced directly or indirectly in one of its return expressions.",
    .category = "Error",
    .code = "7024",
};
pub const generator_implicitly_has_yield_type_ARG_because_it_does_not_yield_any_values_consider_supplying_a_return_type_annotation = DiagnosticMessage{
    .message = "Generator implicitly has yield type '{0s}' because it does not yield any values. Consider supplying a return type annotation.",
    .category = "Error",
    .code = "7025",
};
pub const jsx_element_implicitly_has_type_any_because_no_interface_jsx_ARG_exists = DiagnosticMessage{
    .message = "JSX element implicitly has type 'any' because no interface 'JSX.{0s}' exists.",
    .category = "Error",
    .code = "7026",
};
pub const unreachable_code_detected = DiagnosticMessage{
    .message = "Unreachable code detected.",
    .category = "Error",
    .code = "7027",
};
pub const unused_label = DiagnosticMessage{
    .message = "Unused label.",
    .category = "Error",
    .code = "7028",
};
pub const fallthrough_case_in_switch = DiagnosticMessage{
    .message = "Fallthrough case in switch.",
    .category = "Error",
    .code = "7029",
};
pub const not_all_code_paths_return_a_value = DiagnosticMessage{
    .message = "Not all code paths return a value.",
    .category = "Error",
    .code = "7030",
};
pub const binding_element_ARG_implicitly_has_an_ARG_type = DiagnosticMessage{
    .message = "Binding element '{0s}' implicitly has an '{1s}' type.",
    .category = "Error",
    .code = "7031",
};
pub const property_ARG_implicitly_has_type_any_because_its_set_accessor_lacks_a_parameter_type_annotation = DiagnosticMessage{
    .message = "Property '{0s}' implicitly has type 'any', because its set accessor lacks a parameter type annotation.",
    .category = "Error",
    .code = "7032",
};
pub const property_ARG_implicitly_has_type_any_because_its_get_accessor_lacks_a_return_type_annotation = DiagnosticMessage{
    .message = "Property '{0s}' implicitly has type 'any', because its get accessor lacks a return type annotation.",
    .category = "Error",
    .code = "7033",
};
pub const variable_ARG_implicitly_has_type_ARG_in_some_locations_where_its_type_cannot_be_determined = DiagnosticMessage{
    .message = "Variable '{0s}' implicitly has type '{1s}' in some locations where its type cannot be determined.",
    .category = "Error",
    .code = "7034",
};
pub const try_npm_i_save_dev_types_ARG_if_it_exists_or_add_a_new_declaration_d_ts_file_containing_declare_module_ARG = DiagnosticMessage{
    .message = "Try `npm i --save-dev @types/{1s}` if it exists or add a new declaration (.d.ts) file containing `declare module '{0s}';`",
    .category = "Error",
    .code = "7035",
};
pub const dynamic_import_s_specifier_must_be_of_type_string_but_here_has_type_ARG = DiagnosticMessage{
    .message = "Dynamic import's specifier must be of type 'string', but here has type '{0s}'.",
    .category = "Error",
    .code = "7036",
};
pub const enables_emit_interoperability_between_commonjs_and_es_modules_via_creation_of_namespace_objects_for_all_imports_implies_allowsyntheticdefaultimports = DiagnosticMessage{
    .message = "Enables emit interoperability between CommonJS and ES Modules via creation of namespace objects for all imports. Implies 'allowSyntheticDefaultImports'.",
    .category = "Message",
    .code = "7037",
};
pub const type_originates_at_this_import_a_namespace_style_import_cannot_be_called_or_constructed_and_will_cause_a_failure_at_runtime_consider_using_a_default_import_or_import_require_here_instead = DiagnosticMessage{
    .message = "Type originates at this import. A namespace-style import cannot be called or constructed, and will cause a failure at runtime. Consider using a default import or import require here instead.",
    .category = "Message",
    .code = "7038",
};
pub const mapped_object_type_implicitly_has_an_any_template_type = DiagnosticMessage{
    .message = "Mapped object type implicitly has an 'any' template type.",
    .category = "Error",
    .code = "7039",
};
pub const if_the_ARG_package_actually_exposes_this_module_consider_sending_a_pull_request_to_amend_https_github_com_definitelytyped_definitelytyped_tree_master_types_ARG = DiagnosticMessage{
    .message = "If the '{0s}' package actually exposes this module, consider sending a pull request to amend 'https://github.com/DefinitelyTyped/DefinitelyTyped/tree/master/types/{1s}'",
    .category = "Error",
    .code = "7040",
};
pub const the_containing_arrow_function_captures_the_global_value_of_this = DiagnosticMessage{
    .message = "The containing arrow function captures the global value of 'this'.",
    .category = "Error",
    .code = "7041",
};
pub const module_ARG_was_resolved_to_ARG_but_resolvejsonmodule_is_not_used = DiagnosticMessage{
    .message = "Module '{0s}' was resolved to '{1s}', but '--resolveJsonModule' is not used.",
    .category = "Error",
    .code = "7042",
};
pub const variable_ARG_implicitly_has_an_ARG_type_but_a_better_type_may_be_inferred_from_usage = DiagnosticMessage{
    .message = "Variable '{0s}' implicitly has an '{1s}' type, but a better type may be inferred from usage.",
    .category = "Suggestion",
    .code = "7043",
};
pub const parameter_ARG_implicitly_has_an_ARG_type_but_a_better_type_may_be_inferred_from_usage = DiagnosticMessage{
    .message = "Parameter '{0s}' implicitly has an '{1s}' type, but a better type may be inferred from usage.",
    .category = "Suggestion",
    .code = "7044",
};
pub const member_ARG_implicitly_has_an_ARG_type_but_a_better_type_may_be_inferred_from_usage = DiagnosticMessage{
    .message = "Member '{0s}' implicitly has an '{1s}' type, but a better type may be inferred from usage.",
    .category = "Suggestion",
    .code = "7045",
};
pub const variable_ARG_implicitly_has_type_ARG_in_some_locations_but_a_better_type_may_be_inferred_from_usage = DiagnosticMessage{
    .message = "Variable '{0s}' implicitly has type '{1s}' in some locations, but a better type may be inferred from usage.",
    .category = "Suggestion",
    .code = "7046",
};
pub const rest_parameter_ARG_implicitly_has_an_any_type_but_a_better_type_may_be_inferred_from_usage = DiagnosticMessage{
    .message = "Rest parameter '{0s}' implicitly has an 'any[]' type, but a better type may be inferred from usage.",
    .category = "Suggestion",
    .code = "7047",
};
pub const property_ARG_implicitly_has_type_any_but_a_better_type_for_its_get_accessor_may_be_inferred_from_usage = DiagnosticMessage{
    .message = "Property '{0s}' implicitly has type 'any', but a better type for its get accessor may be inferred from usage.",
    .category = "Suggestion",
    .code = "7048",
};
pub const property_ARG_implicitly_has_type_any_but_a_better_type_for_its_set_accessor_may_be_inferred_from_usage = DiagnosticMessage{
    .message = "Property '{0s}' implicitly has type 'any', but a better type for its set accessor may be inferred from usage.",
    .category = "Suggestion",
    .code = "7049",
};
pub const ARG_implicitly_has_an_ARG_return_type_but_a_better_type_may_be_inferred_from_usage = DiagnosticMessage{
    .message = "'{0s}' implicitly has an '{1s}' return type, but a better type may be inferred from usage.",
    .category = "Suggestion",
    .code = "7050",
};
pub const parameter_has_a_name_but_no_type_did_you_mean_ARG_ARG = DiagnosticMessage{
    .message = "Parameter has a name but no type. Did you mean '{0s}: {1s}'?",
    .category = "Error",
    .code = "7051",
};
pub const element_implicitly_has_an_any_type_because_type_ARG_has_no_index_signature_did_you_mean_to_call_ARG = DiagnosticMessage{
    .message = "Element implicitly has an 'any' type because type '{0s}' has no index signature. Did you mean to call '{1s}'?",
    .category = "Error",
    .code = "7052",
};
pub const element_implicitly_has_an_any_type_because_expression_of_type_ARG_can_t_be_used_to_index_type_ARG = DiagnosticMessage{
    .message = "Element implicitly has an 'any' type because expression of type '{0s}' can't be used to index type '{1s}'.",
    .category = "Error",
    .code = "7053",
};
pub const no_index_signature_with_a_parameter_of_type_ARG_was_found_on_type_ARG = DiagnosticMessage{
    .message = "No index signature with a parameter of type '{0s}' was found on type '{1s}'.",
    .category = "Error",
    .code = "7054",
};
pub const ARG_which_lacks_return_type_annotation_implicitly_has_an_ARG_yield_type = DiagnosticMessage{
    .message = "'{0s}', which lacks return-type annotation, implicitly has an '{1s}' yield type.",
    .category = "Error",
    .code = "7055",
};
pub const the_inferred_type_of_this_node_exceeds_the_maximum_length_the_compiler_will_serialize_an_explicit_type_annotation_is_needed = DiagnosticMessage{
    .message = "The inferred type of this node exceeds the maximum length the compiler will serialize. An explicit type annotation is needed.",
    .category = "Error",
    .code = "7056",
};
pub const yield_expression_implicitly_results_in_an_any_type_because_its_containing_generator_lacks_a_return_type_annotation = DiagnosticMessage{
    .message = "'yield' expression implicitly results in an 'any' type because its containing generator lacks a return-type annotation.",
    .category = "Error",
    .code = "7057",
};
pub const if_the_ARG_package_actually_exposes_this_module_try_adding_a_new_declaration_d_ts_file_containing_declare_module_ARG = DiagnosticMessage{
    .message = "If the '{0s}' package actually exposes this module, try adding a new declaration (.d.ts) file containing `declare module '{1s}';`",
    .category = "Error",
    .code = "7058",
};
pub const this_syntax_is_reserved_in_files_with_the_mts_or_cts_extension_use_an_as_expression_instead = DiagnosticMessage{
    .message = "This syntax is reserved in files with the .mts or .cts extension. Use an `as` expression instead.",
    .category = "Error",
    .code = "7059",
};
pub const this_syntax_is_reserved_in_files_with_the_mts_or_cts_extension_add_a_trailing_comma_or_explicit_constraint = DiagnosticMessage{
    .message = "This syntax is reserved in files with the .mts or .cts extension. Add a trailing comma or explicit constraint.",
    .category = "Error",
    .code = "7060",
};
pub const a_mapped_type_may_not_declare_properties_or_methods = DiagnosticMessage{
    .message = "A mapped type may not declare properties or methods.",
    .category = "Error",
    .code = "7061",
};
pub const you_cannot_rename_this_element = DiagnosticMessage{
    .message = "You cannot rename this element.",
    .category = "Error",
    .code = "8000",
};
pub const you_cannot_rename_elements_that_are_defined_in_the_standard_typescript_library = DiagnosticMessage{
    .message = "You cannot rename elements that are defined in the standard TypeScript library.",
    .category = "Error",
    .code = "8001",
};
pub const import_can_only_be_used_in_typescript_files = DiagnosticMessage{
    .message = "'import ... =' can only be used in TypeScript files.",
    .category = "Error",
    .code = "8002",
};
pub const export_can_only_be_used_in_typescript_files = DiagnosticMessage{
    .message = "'export =' can only be used in TypeScript files.",
    .category = "Error",
    .code = "8003",
};
pub const type_parameter_declarations_can_only_be_used_in_typescript_files = DiagnosticMessage{
    .message = "Type parameter declarations can only be used in TypeScript files.",
    .category = "Error",
    .code = "8004",
};
pub const implements_clauses_can_only_be_used_in_typescript_files = DiagnosticMessage{
    .message = "'implements' clauses can only be used in TypeScript files.",
    .category = "Error",
    .code = "8005",
};
pub const ARG_declarations_can_only_be_used_in_typescript_files = DiagnosticMessage{
    .message = "'{0s}' declarations can only be used in TypeScript files.",
    .category = "Error",
    .code = "8006",
};
pub const type_aliases_can_only_be_used_in_typescript_files = DiagnosticMessage{
    .message = "Type aliases can only be used in TypeScript files.",
    .category = "Error",
    .code = "8008",
};
pub const the_ARG_modifier_can_only_be_used_in_typescript_files = DiagnosticMessage{
    .message = "The '{0s}' modifier can only be used in TypeScript files.",
    .category = "Error",
    .code = "8009",
};
pub const type_annotations_can_only_be_used_in_typescript_files = DiagnosticMessage{
    .message = "Type annotations can only be used in TypeScript files.",
    .category = "Error",
    .code = "8010",
};
pub const type_arguments_can_only_be_used_in_typescript_files = DiagnosticMessage{
    .message = "Type arguments can only be used in TypeScript files.",
    .category = "Error",
    .code = "8011",
};
pub const parameter_modifiers_can_only_be_used_in_typescript_files = DiagnosticMessage{
    .message = "Parameter modifiers can only be used in TypeScript files.",
    .category = "Error",
    .code = "8012",
};
pub const non_null_assertions_can_only_be_used_in_typescript_files = DiagnosticMessage{
    .message = "Non-null assertions can only be used in TypeScript files.",
    .category = "Error",
    .code = "8013",
};
pub const type_assertion_expressions_can_only_be_used_in_typescript_files = DiagnosticMessage{
    .message = "Type assertion expressions can only be used in TypeScript files.",
    .category = "Error",
    .code = "8016",
};
pub const signature_declarations_can_only_be_used_in_typescript_files = DiagnosticMessage{
    .message = "Signature declarations can only be used in TypeScript files.",
    .category = "Error",
    .code = "8017",
};
pub const report_errors_in_js_files = DiagnosticMessage{
    .message = "Report errors in .js files.",
    .category = "Message",
    .code = "8019",
};
pub const jsdoc_types_can_only_be_used_inside_documentation_comments = DiagnosticMessage{
    .message = "JSDoc types can only be used inside documentation comments.",
    .category = "Error",
    .code = "8020",
};
pub const jsdoc_typedef_tag_should_either_have_a_type_annotation_or_be_followed_by_property_or_member_tags = DiagnosticMessage{
    .message = "JSDoc '@typedef' tag should either have a type annotation or be followed by '@property' or '@member' tags.",
    .category = "Error",
    .code = "8021",
};
pub const jsdoc_ARG_is_not_attached_to_a_class = DiagnosticMessage{
    .message = "JSDoc '@{0s}' is not attached to a class.",
    .category = "Error",
    .code = "8022",
};
pub const jsdoc_ARG_ARG_does_not_match_the_extends_ARG_clause = DiagnosticMessage{
    .message = "JSDoc '@{0s} {1s}' does not match the 'extends {2s}' clause.",
    .category = "Error",
    .code = "8023",
};
pub const jsdoc_param_tag_has_name_ARG_but_there_is_no_parameter_with_that_name = DiagnosticMessage{
    .message = "JSDoc '@param' tag has name '{0s}', but there is no parameter with that name.",
    .category = "Error",
    .code = "8024",
};
pub const class_declarations_cannot_have_more_than_one_augments_or_extends_tag = DiagnosticMessage{
    .message = "Class declarations cannot have more than one '@augments' or '@extends' tag.",
    .category = "Error",
    .code = "8025",
};
pub const expected_ARG_type_arguments_provide_these_with_an_extends_tag = DiagnosticMessage{
    .message = "Expected {0s} type arguments; provide these with an '@extends' tag.",
    .category = "Error",
    .code = "8026",
};
pub const expected_ARG_ARG_type_arguments_provide_these_with_an_extends_tag = DiagnosticMessage{
    .message = "Expected {0s}-{1s} type arguments; provide these with an '@extends' tag.",
    .category = "Error",
    .code = "8027",
};
pub const jsdoc_may_only_appear_in_the_last_parameter_of_a_signature = DiagnosticMessage{
    .message = "JSDoc '...' may only appear in the last parameter of a signature.",
    .category = "Error",
    .code = "8028",
};
pub const jsdoc_param_tag_has_name_ARG_but_there_is_no_parameter_with_that_name_it_would_match_arguments_if_it_had_an_array_type = DiagnosticMessage{
    .message = "JSDoc '@param' tag has name '{0s}', but there is no parameter with that name. It would match 'arguments' if it had an array type.",
    .category = "Error",
    .code = "8029",
};
pub const the_type_of_a_function_declaration_must_match_the_function_s_signature = DiagnosticMessage{
    .message = "The type of a function declaration must match the function's signature.",
    .category = "Error",
    .code = "8030",
};
pub const you_cannot_rename_a_module_via_a_global_import = DiagnosticMessage{
    .message = "You cannot rename a module via a global import.",
    .category = "Error",
    .code = "8031",
};
pub const qualified_name_ARG_is_not_allowed_without_a_leading_param_ARG_ARG = DiagnosticMessage{
    .message = "Qualified name '{0s}' is not allowed without a leading '@param {{object} {1s}'.",
    .category = "Error",
    .code = "8032",
};
pub const a_jsdoc_typedef_comment_may_not_contain_multiple_type_tags = DiagnosticMessage{
    .message = "A JSDoc '@typedef' comment may not contain multiple '@type' tags.",
    .category = "Error",
    .code = "8033",
};
pub const the_tag_was_first_specified_here = DiagnosticMessage{
    .message = "The tag was first specified here.",
    .category = "Error",
    .code = "8034",
};
pub const you_cannot_rename_elements_that_are_defined_in_a_node_modules_folder = DiagnosticMessage{
    .message = "You cannot rename elements that are defined in a 'node_modules' folder.",
    .category = "Error",
    .code = "8035",
};
pub const you_cannot_rename_elements_that_are_defined_in_another_node_modules_folder = DiagnosticMessage{
    .message = "You cannot rename elements that are defined in another 'node_modules' folder.",
    .category = "Error",
    .code = "8036",
};
pub const type_satisfaction_expressions_can_only_be_used_in_typescript_files = DiagnosticMessage{
    .message = "Type satisfaction expressions can only be used in TypeScript files.",
    .category = "Error",
    .code = "8037",
};
pub const decorators_may_not_appear_after_export_or_export_default_if_they_also_appear_before_export = DiagnosticMessage{
    .message = "Decorators may not appear after 'export' or 'export default' if they also appear before 'export'.",
    .category = "Error",
    .code = "8038",
};
pub const a_jsdoc_template_tag_may_not_follow_a_typedef_callback_or_overload_tag = DiagnosticMessage{
    .message = "A JSDoc '@template' tag may not follow a '@typedef', '@callback', or '@overload' tag",
    .category = "Error",
    .code = "8039",
};
pub const declaration_emit_for_this_file_requires_using_private_name_ARG_an_explicit_type_annotation_may_unblock_declaration_emit = DiagnosticMessage{
    .message = "Declaration emit for this file requires using private name '{0s}'. An explicit type annotation may unblock declaration emit.",
    .category = "Error",
    .code = "9005",
};
pub const declaration_emit_for_this_file_requires_using_private_name_ARG_from_module_ARG_an_explicit_type_annotation_may_unblock_declaration_emit = DiagnosticMessage{
    .message = "Declaration emit for this file requires using private name '{0s}' from module '{1s}'. An explicit type annotation may unblock declaration emit.",
    .category = "Error",
    .code = "9006",
};
pub const function_must_have_an_explicit_return_type_annotation_with_isolateddeclarations = DiagnosticMessage{
    .message = "Function must have an explicit return type annotation with --isolatedDeclarations.",
    .category = "Error",
    .code = "9007",
};
pub const method_must_have_an_explicit_return_type_annotation_with_isolateddeclarations = DiagnosticMessage{
    .message = "Method must have an explicit return type annotation with --isolatedDeclarations.",
    .category = "Error",
    .code = "9008",
};
pub const at_least_one_accessor_must_have_an_explicit_return_type_annotation_with_isolateddeclarations = DiagnosticMessage{
    .message = "At least one accessor must have an explicit return type annotation with --isolatedDeclarations.",
    .category = "Error",
    .code = "9009",
};
pub const variable_must_have_an_explicit_type_annotation_with_isolateddeclarations = DiagnosticMessage{
    .message = "Variable must have an explicit type annotation with --isolatedDeclarations.",
    .category = "Error",
    .code = "9010",
};
pub const parameter_must_have_an_explicit_type_annotation_with_isolateddeclarations = DiagnosticMessage{
    .message = "Parameter must have an explicit type annotation with --isolatedDeclarations.",
    .category = "Error",
    .code = "9011",
};
pub const property_must_have_an_explicit_type_annotation_with_isolateddeclarations = DiagnosticMessage{
    .message = "Property must have an explicit type annotation with --isolatedDeclarations.",
    .category = "Error",
    .code = "9012",
};
pub const expression_type_can_t_be_inferred_with_isolateddeclarations = DiagnosticMessage{
    .message = "Expression type can't be inferred with --isolatedDeclarations.",
    .category = "Error",
    .code = "9013",
};
pub const computed_properties_must_be_number_or_string_literals_variables_or_dotted_expressions_with_isolateddeclarations = DiagnosticMessage{
    .message = "Computed properties must be number or string literals, variables or dotted expressions with --isolatedDeclarations.",
    .category = "Error",
    .code = "9014",
};
pub const objects_that_contain_spread_assignments_can_t_be_inferred_with_isolateddeclarations = DiagnosticMessage{
    .message = "Objects that contain spread assignments can't be inferred with --isolatedDeclarations.",
    .category = "Error",
    .code = "9015",
};
pub const objects_that_contain_shorthand_properties_can_t_be_inferred_with_isolateddeclarations = DiagnosticMessage{
    .message = "Objects that contain shorthand properties can't be inferred with --isolatedDeclarations.",
    .category = "Error",
    .code = "9016",
};
pub const only_const_arrays_can_be_inferred_with_isolateddeclarations = DiagnosticMessage{
    .message = "Only const arrays can be inferred with --isolatedDeclarations.",
    .category = "Error",
    .code = "9017",
};
pub const arrays_with_spread_elements_can_t_inferred_with_isolateddeclarations = DiagnosticMessage{
    .message = "Arrays with spread elements can't inferred with --isolatedDeclarations.",
    .category = "Error",
    .code = "9018",
};
pub const binding_elements_can_t_be_exported_directly_with_isolateddeclarations = DiagnosticMessage{
    .message = "Binding elements can't be exported directly with --isolatedDeclarations.",
    .category = "Error",
    .code = "9019",
};
pub const enum_member_initializers_must_be_computable_without_references_to_external_symbols_with_isolateddeclarations = DiagnosticMessage{
    .message = "Enum member initializers must be computable without references to external symbols with --isolatedDeclarations.",
    .category = "Error",
    .code = "9020",
};
pub const extends_clause_can_t_contain_an_expression_with_isolateddeclarations = DiagnosticMessage{
    .message = "Extends clause can't contain an expression with --isolatedDeclarations.",
    .category = "Error",
    .code = "9021",
};
pub const inference_from_class_expressions_is_not_supported_with_isolateddeclarations = DiagnosticMessage{
    .message = "Inference from class expressions is not supported with --isolatedDeclarations.",
    .category = "Error",
    .code = "9022",
};
pub const assigning_properties_to_functions_without_declaring_them_is_not_supported_with_isolateddeclarations_add_an_explicit_declaration_for_the_properties_assigned_to_this_function = DiagnosticMessage{
    .message = "Assigning properties to functions without declaring them is not supported with --isolatedDeclarations. Add an explicit declaration for the properties assigned to this function.",
    .category = "Error",
    .code = "9023",
};
pub const declaration_emit_for_this_parameter_requires_implicitly_adding_undefined_to_it_s_type_this_is_not_supported_with_isolateddeclarations = DiagnosticMessage{
    .message = "Declaration emit for this parameter requires implicitly adding undefined to it's type. This is not supported with --isolatedDeclarations.",
    .category = "Error",
    .code = "9025",
};
pub const declaration_emit_for_this_file_requires_preserving_this_import_for_augmentations_this_is_not_supported_with_isolateddeclarations = DiagnosticMessage{
    .message = "Declaration emit for this file requires preserving this import for augmentations. This is not supported with --isolatedDeclarations.",
    .category = "Error",
    .code = "9026",
};
pub const add_a_type_annotation_to_the_variable_ARG = DiagnosticMessage{
    .message = "Add a type annotation to the variable {0s}.",
    .category = "Error",
    .code = "9027",
};
pub const add_a_type_annotation_to_the_parameter_ARG = DiagnosticMessage{
    .message = "Add a type annotation to the parameter {0s}.",
    .category = "Error",
    .code = "9028",
};
pub const add_a_type_annotation_to_the_property_ARG = DiagnosticMessage{
    .message = "Add a type annotation to the property {0s}.",
    .category = "Error",
    .code = "9029",
};
pub const add_a_return_type_to_the_function_expression = DiagnosticMessage{
    .message = "Add a return type to the function expression.",
    .category = "Error",
    .code = "9030",
};
pub const add_a_return_type_to_the_function_declaration = DiagnosticMessage{
    .message = "Add a return type to the function declaration.",
    .category = "Error",
    .code = "9031",
};
pub const add_a_return_type_to_the_get_accessor_declaration = DiagnosticMessage{
    .message = "Add a return type to the get accessor declaration.",
    .category = "Error",
    .code = "9032",
};
pub const add_a_type_to_parameter_of_the_set_accessor_declaration = DiagnosticMessage{
    .message = "Add a type to parameter of the set accessor declaration.",
    .category = "Error",
    .code = "9033",
};
pub const add_a_return_type_to_the_method = DiagnosticMessage{
    .message = "Add a return type to the method",
    .category = "Error",
    .code = "9034",
};
pub const add_satisfies_and_a_type_assertion_to_this_expression_satisfies_t_as_t_to_make_the_type_explicit = DiagnosticMessage{
    .message = "Add satisfies and a type assertion to this expression (satisfies T as T) to make the type explicit.",
    .category = "Error",
    .code = "9035",
};
pub const move_the_expression_in_default_export_to_a_variable_and_add_a_type_annotation_to_it = DiagnosticMessage{
    .message = "Move the expression in default export to a variable and add a type annotation to it.",
    .category = "Error",
    .code = "9036",
};
pub const default_exports_can_t_be_inferred_with_isolateddeclarations = DiagnosticMessage{
    .message = "Default exports can't be inferred with --isolatedDeclarations.",
    .category = "Error",
    .code = "9037",
};
pub const computed_property_names_on_class_or_object_literals_cannot_be_inferred_with_isolateddeclarations = DiagnosticMessage{
    .message = "Computed property names on class or object literals cannot be inferred with --isolatedDeclarations.",
    .category = "Error",
    .code = "9038",
};
pub const type_containing_private_name_ARG_can_t_be_used_with_isolateddeclarations = DiagnosticMessage{
    .message = "Type containing private name '{0s}' can't be used with --isolatedDeclarations.",
    .category = "Error",
    .code = "9039",
};
pub const jsx_attributes_must_only_be_assigned_a_non_empty_expression = DiagnosticMessage{
    .message = "JSX attributes must only be assigned a non-empty 'expression'.",
    .category = "Error",
    .code = "17000",
};
pub const jsx_elements_cannot_have_multiple_attributes_with_the_same_name = DiagnosticMessage{
    .message = "JSX elements cannot have multiple attributes with the same name.",
    .category = "Error",
    .code = "17001",
};
pub const expected_corresponding_jsx_closing_tag_for_ARG = DiagnosticMessage{
    .message = "Expected corresponding JSX closing tag for '{0s}'.",
    .category = "Error",
    .code = "17002",
};
pub const cannot_use_jsx_unless_the_jsx_flag_is_provided = DiagnosticMessage{
    .message = "Cannot use JSX unless the '--jsx' flag is provided.",
    .category = "Error",
    .code = "17004",
};
pub const a_constructor_cannot_contain_a_super_call_when_its_class_extends_null = DiagnosticMessage{
    .message = "A constructor cannot contain a 'super' call when its class extends 'null'.",
    .category = "Error",
    .code = "17005",
};
pub const an_unary_expression_with_the_ARG_operator_is_not_allowed_in_the_left_hand_side_of_an_exponentiation_expression_consider_enclosing_the_expression_in_parentheses = DiagnosticMessage{
    .message = "An unary expression with the '{0s}' operator is not allowed in the left-hand side of an exponentiation expression. Consider enclosing the expression in parentheses.",
    .category = "Error",
    .code = "17006",
};
pub const a_type_assertion_expression_is_not_allowed_in_the_left_hand_side_of_an_exponentiation_expression_consider_enclosing_the_expression_in_parentheses = DiagnosticMessage{
    .message = "A type assertion expression is not allowed in the left-hand side of an exponentiation expression. Consider enclosing the expression in parentheses.",
    .category = "Error",
    .code = "17007",
};
pub const jsx_element_ARG_has_no_corresponding_closing_tag = DiagnosticMessage{
    .message = "JSX element '{0s}' has no corresponding closing tag.",
    .category = "Error",
    .code = "17008",
};
pub const super_must_be_called_before_accessing_this_in_the_constructor_of_a_derived_class = DiagnosticMessage{
    .message = "'super' must be called before accessing 'this' in the constructor of a derived class.",
    .category = "Error",
    .code = "17009",
};
pub const unknown_type_acquisition_option_ARG = DiagnosticMessage{
    .message = "Unknown type acquisition option '{0s}'.",
    .category = "Error",
    .code = "17010",
};
pub const super_must_be_called_before_accessing_a_property_of_super_in_the_constructor_of_a_derived_class = DiagnosticMessage{
    .message = "'super' must be called before accessing a property of 'super' in the constructor of a derived class.",
    .category = "Error",
    .code = "17011",
};
pub const ARG_is_not_a_valid_meta_property_for_keyword_ARG_did_you_mean_ARG = DiagnosticMessage{
    .message = "'{0s}' is not a valid meta-property for keyword '{1s}'. Did you mean '{2s}'?",
    .category = "Error",
    .code = "17012",
};
pub const meta_property_ARG_is_only_allowed_in_the_body_of_a_function_declaration_function_expression_or_constructor = DiagnosticMessage{
    .message = "Meta-property '{0s}' is only allowed in the body of a function declaration, function expression, or constructor.",
    .category = "Error",
    .code = "17013",
};
pub const jsx_fragment_has_no_corresponding_closing_tag = DiagnosticMessage{
    .message = "JSX fragment has no corresponding closing tag.",
    .category = "Error",
    .code = "17014",
};
pub const expected_corresponding_closing_tag_for_jsx_fragment = DiagnosticMessage{
    .message = "Expected corresponding closing tag for JSX fragment.",
    .category = "Error",
    .code = "17015",
};
pub const the_jsxfragmentfactory_compiler_option_must_be_provided_to_use_jsx_fragments_with_the_jsxfactory_compiler_option = DiagnosticMessage{
    .message = "The 'jsxFragmentFactory' compiler option must be provided to use JSX fragments with the 'jsxFactory' compiler option.",
    .category = "Error",
    .code = "17016",
};
pub const an_jsxfrag_pragma_is_required_when_using_an_jsx_pragma_with_jsx_fragments = DiagnosticMessage{
    .message = "An @jsxFrag pragma is required when using an @jsx pragma with JSX fragments.",
    .category = "Error",
    .code = "17017",
};
pub const unknown_type_acquisition_option_ARG_did_you_mean_ARG = DiagnosticMessage{
    .message = "Unknown type acquisition option '{0s}'. Did you mean '{1s}'?",
    .category = "Error",
    .code = "17018",
};
pub const ARG_at_the_end_of_a_type_is_not_valid_typescript_syntax_did_you_mean_to_write_ARG = DiagnosticMessage{
    .message = "'{0s}' at the end of a type is not valid TypeScript syntax. Did you mean to write '{1s}'?",
    .category = "Error",
    .code = "17019",
};
pub const ARG_at_the_start_of_a_type_is_not_valid_typescript_syntax_did_you_mean_to_write_ARG = DiagnosticMessage{
    .message = "'{0s}' at the start of a type is not valid TypeScript syntax. Did you mean to write '{1s}'?",
    .category = "Error",
    .code = "17020",
};
pub const unicode_escape_sequence_cannot_appear_here = DiagnosticMessage{
    .message = "Unicode escape sequence cannot appear here.",
    .category = "Error",
    .code = "17021",
};
pub const circularity_detected_while_resolving_configuration_ARG = DiagnosticMessage{
    .message = "Circularity detected while resolving configuration: {0s}",
    .category = "Error",
    .code = "18000",
};
pub const the_files_list_in_config_file_ARG_is_empty = DiagnosticMessage{
    .message = "The 'files' list in config file '{0s}' is empty.",
    .category = "Error",
    .code = "18002",
};
pub const no_inputs_were_found_in_config_file_ARG_specified_include_paths_were_ARG_and_exclude_paths_were_ARG = DiagnosticMessage{
    .message = "No inputs were found in config file '{0s}'. Specified 'include' paths were '{1s}' and 'exclude' paths were '{2s}'.",
    .category = "Error",
    .code = "18003",
};
pub const file_is_a_commonjs_module_it_may_be_converted_to_an_es_module = DiagnosticMessage{
    .message = "File is a CommonJS module; it may be converted to an ES module.",
    .category = "Suggestion",
    .code = "80001",
};
pub const this_constructor_function_may_be_converted_to_a_class_declaration = DiagnosticMessage{
    .message = "This constructor function may be converted to a class declaration.",
    .category = "Suggestion",
    .code = "80002",
};
pub const import_may_be_converted_to_a_default_import = DiagnosticMessage{
    .message = "Import may be converted to a default import.",
    .category = "Suggestion",
    .code = "80003",
};
pub const jsdoc_types_may_be_moved_to_typescript_types = DiagnosticMessage{
    .message = "JSDoc types may be moved to TypeScript types.",
    .category = "Suggestion",
    .code = "80004",
};
pub const require_call_may_be_converted_to_an_import = DiagnosticMessage{
    .message = "'require' call may be converted to an import.",
    .category = "Suggestion",
    .code = "80005",
};
pub const this_may_be_converted_to_an_async_function = DiagnosticMessage{
    .message = "This may be converted to an async function.",
    .category = "Suggestion",
    .code = "80006",
};
pub const await_has_no_effect_on_the_type_of_this_expression = DiagnosticMessage{
    .message = "'await' has no effect on the type of this expression.",
    .category = "Suggestion",
    .code = "80007",
};
pub const numeric_literals_with_absolute_values_equal_to_2_53_or_greater_are_too_large_to_be_represented_accurately_as_integers = DiagnosticMessage{
    .message = "Numeric literals with absolute values equal to 2^53 or greater are too large to be represented accurately as integers.",
    .category = "Suggestion",
    .code = "80008",
};
pub const jsdoc_typedef_may_be_converted_to_typescript_type = DiagnosticMessage{
    .message = "JSDoc typedef may be converted to TypeScript type.",
    .category = "Suggestion",
    .code = "80009",
};
pub const jsdoc_typedefs_may_be_converted_to_typescript_types = DiagnosticMessage{
    .message = "JSDoc typedefs may be converted to TypeScript types.",
    .category = "Suggestion",
    .code = "80010",
};
pub const add_missing_super_call = DiagnosticMessage{
    .message = "Add missing 'super()' call",
    .category = "Message",
    .code = "90001",
};
pub const make_super_call_the_first_statement_in_the_constructor = DiagnosticMessage{
    .message = "Make 'super()' call the first statement in the constructor",
    .category = "Message",
    .code = "90002",
};
pub const change_extends_to_implements = DiagnosticMessage{
    .message = "Change 'extends' to 'implements'",
    .category = "Message",
    .code = "90003",
};
pub const remove_unused_declaration_for_ARG = DiagnosticMessage{
    .message = "Remove unused declaration for: '{0s}'",
    .category = "Message",
    .code = "90004",
};
pub const remove_import_from_ARG = DiagnosticMessage{
    .message = "Remove import from '{0s}'",
    .category = "Message",
    .code = "90005",
};
pub const implement_interface_ARG = DiagnosticMessage{
    .message = "Implement interface '{0s}'",
    .category = "Message",
    .code = "90006",
};
pub const implement_inherited_abstract_class = DiagnosticMessage{
    .message = "Implement inherited abstract class",
    .category = "Message",
    .code = "90007",
};
pub const add_ARG_to_unresolved_variable = DiagnosticMessage{
    .message = "Add '{0s}.' to unresolved variable",
    .category = "Message",
    .code = "90008",
};
pub const remove_variable_statement = DiagnosticMessage{
    .message = "Remove variable statement",
    .category = "Message",
    .code = "90010",
};
pub const remove_template_tag = DiagnosticMessage{
    .message = "Remove template tag",
    .category = "Message",
    .code = "90011",
};
pub const remove_type_parameters = DiagnosticMessage{
    .message = "Remove type parameters",
    .category = "Message",
    .code = "90012",
};
pub const import_ARG_from_ARG = DiagnosticMessage{
    .message = "Import '{0s}' from \"{1s}\"",
    .category = "Message",
    .code = "90013",
};
pub const change_ARG_to_ARG = DiagnosticMessage{
    .message = "Change '{0s}' to '{1s}'",
    .category = "Message",
    .code = "90014",
};
pub const declare_property_ARG = DiagnosticMessage{
    .message = "Declare property '{0s}'",
    .category = "Message",
    .code = "90016",
};
pub const add_index_signature_for_property_ARG = DiagnosticMessage{
    .message = "Add index signature for property '{0s}'",
    .category = "Message",
    .code = "90017",
};
pub const disable_checking_for_this_file = DiagnosticMessage{
    .message = "Disable checking for this file",
    .category = "Message",
    .code = "90018",
};
pub const ignore_this_error_message = DiagnosticMessage{
    .message = "Ignore this error message",
    .category = "Message",
    .code = "90019",
};
pub const initialize_property_ARG_in_the_constructor = DiagnosticMessage{
    .message = "Initialize property '{0s}' in the constructor",
    .category = "Message",
    .code = "90020",
};
pub const initialize_static_property_ARG = DiagnosticMessage{
    .message = "Initialize static property '{0s}'",
    .category = "Message",
    .code = "90021",
};
pub const change_spelling_to_ARG = DiagnosticMessage{
    .message = "Change spelling to '{0s}'",
    .category = "Message",
    .code = "90022",
};
pub const declare_method_ARG = DiagnosticMessage{
    .message = "Declare method '{0s}'",
    .category = "Message",
    .code = "90023",
};
pub const declare_static_method_ARG = DiagnosticMessage{
    .message = "Declare static method '{0s}'",
    .category = "Message",
    .code = "90024",
};
pub const prefix_ARG_with_an_underscore = DiagnosticMessage{
    .message = "Prefix '{0s}' with an underscore",
    .category = "Message",
    .code = "90025",
};
pub const rewrite_as_the_indexed_access_type_ARG = DiagnosticMessage{
    .message = "Rewrite as the indexed access type '{0s}'",
    .category = "Message",
    .code = "90026",
};
pub const declare_static_property_ARG = DiagnosticMessage{
    .message = "Declare static property '{0s}'",
    .category = "Message",
    .code = "90027",
};
pub const call_decorator_expression = DiagnosticMessage{
    .message = "Call decorator expression",
    .category = "Message",
    .code = "90028",
};
pub const add_async_modifier_to_containing_function = DiagnosticMessage{
    .message = "Add async modifier to containing function",
    .category = "Message",
    .code = "90029",
};
pub const replace_infer_ARG_with_unknown = DiagnosticMessage{
    .message = "Replace 'infer {0s}' with 'unknown'",
    .category = "Message",
    .code = "90030",
};
pub const replace_all_unused_infer_with_unknown = DiagnosticMessage{
    .message = "Replace all unused 'infer' with 'unknown'",
    .category = "Message",
    .code = "90031",
};
pub const add_parameter_name = DiagnosticMessage{
    .message = "Add parameter name",
    .category = "Message",
    .code = "90034",
};
pub const declare_private_property_ARG = DiagnosticMessage{
    .message = "Declare private property '{0s}'",
    .category = "Message",
    .code = "90035",
};
pub const replace_ARG_with_promise_ARG = DiagnosticMessage{
    .message = "Replace '{0s}' with 'Promise<{1s}>'",
    .category = "Message",
    .code = "90036",
};
pub const fix_all_incorrect_return_type_of_an_async_functions = DiagnosticMessage{
    .message = "Fix all incorrect return type of an async functions",
    .category = "Message",
    .code = "90037",
};
pub const declare_private_method_ARG = DiagnosticMessage{
    .message = "Declare private method '{0s}'",
    .category = "Message",
    .code = "90038",
};
pub const remove_unused_destructuring_declaration = DiagnosticMessage{
    .message = "Remove unused destructuring declaration",
    .category = "Message",
    .code = "90039",
};
pub const remove_unused_declarations_for_ARG = DiagnosticMessage{
    .message = "Remove unused declarations for: '{0s}'",
    .category = "Message",
    .code = "90041",
};
pub const declare_a_private_field_named_ARG = DiagnosticMessage{
    .message = "Declare a private field named '{0s}'.",
    .category = "Message",
    .code = "90053",
};
pub const includes_imports_of_types_referenced_by_ARG = DiagnosticMessage{
    .message = "Includes imports of types referenced by '{0s}'",
    .category = "Message",
    .code = "90054",
};
pub const remove_type_from_import_declaration_from_ARG = DiagnosticMessage{
    .message = "Remove 'type' from import declaration from \"{0s}\"",
    .category = "Message",
    .code = "90055",
};
pub const remove_type_from_import_of_ARG_from_ARG = DiagnosticMessage{
    .message = "Remove 'type' from import of '{0s}' from \"{1s}\"",
    .category = "Message",
    .code = "90056",
};
pub const add_import_from_ARG = DiagnosticMessage{
    .message = "Add import from \"{0s}\"",
    .category = "Message",
    .code = "90057",
};
pub const update_import_from_ARG = DiagnosticMessage{
    .message = "Update import from \"{0s}\"",
    .category = "Message",
    .code = "90058",
};
pub const export_ARG_from_module_ARG = DiagnosticMessage{
    .message = "Export '{0s}' from module '{1s}'",
    .category = "Message",
    .code = "90059",
};
pub const export_all_referenced_locals = DiagnosticMessage{
    .message = "Export all referenced locals",
    .category = "Message",
    .code = "90060",
};
pub const update_modifiers_of_ARG = DiagnosticMessage{
    .message = "Update modifiers of '{0s}'",
    .category = "Message",
    .code = "90061",
};
pub const add_annotation_of_type_ARG = DiagnosticMessage{
    .message = "Add annotation of type '{0s}'",
    .category = "Message",
    .code = "90062",
};
pub const add_return_type_ARG = DiagnosticMessage{
    .message = "Add return type '{0s}'",
    .category = "Message",
    .code = "90063",
};
pub const extract_base_class_to_variable = DiagnosticMessage{
    .message = "Extract base class to variable",
    .category = "Message",
    .code = "90064",
};
pub const extract_default_export_to_variable = DiagnosticMessage{
    .message = "Extract default export to variable",
    .category = "Message",
    .code = "90065",
};
pub const extract_binding_expressions_to_variable = DiagnosticMessage{
    .message = "Extract binding expressions to variable",
    .category = "Message",
    .code = "90066",
};
pub const add_all_missing_type_annotations = DiagnosticMessage{
    .message = "Add all missing type annotations",
    .category = "Message",
    .code = "90067",
};
pub const add_satisfies_and_an_inline_type_assertion_with_ARG = DiagnosticMessage{
    .message = "Add satisfies and an inline type assertion with '{0s}'",
    .category = "Message",
    .code = "90068",
};
pub const extract_to_variable_and_replace_with_ARG_as_typeof_ARG = DiagnosticMessage{
    .message = "Extract to variable and replace with '{0s} as typeof {0s}'",
    .category = "Message",
    .code = "90069",
};
pub const mark_array_literal_as_const = DiagnosticMessage{
    .message = "Mark array literal as const",
    .category = "Message",
    .code = "90070",
};
pub const annotate_types_of_properties_expando_function_in_a_namespace = DiagnosticMessage{
    .message = "Annotate types of properties expando function in a namespace",
    .category = "Message",
    .code = "90071",
};
pub const convert_function_to_an_es2015_class = DiagnosticMessage{
    .message = "Convert function to an ES2015 class",
    .category = "Message",
    .code = "95001",
};
pub const convert_ARG_to_ARG_in_ARG = DiagnosticMessage{
    .message = "Convert '{0s}' to '{1s} in {0s}'",
    .category = "Message",
    .code = "95003",
};
pub const extract_to_ARG_in_ARG = DiagnosticMessage{
    .message = "Extract to {0s} in {1s}",
    .category = "Message",
    .code = "95004",
};
pub const extract_function = DiagnosticMessage{
    .message = "Extract function",
    .category = "Message",
    .code = "95005",
};
pub const extract_constant = DiagnosticMessage{
    .message = "Extract constant",
    .category = "Message",
    .code = "95006",
};
pub const extract_to_ARG_in_enclosing_scope = DiagnosticMessage{
    .message = "Extract to {0s} in enclosing scope",
    .category = "Message",
    .code = "95007",
};
pub const extract_to_ARG_in_ARG_scope = DiagnosticMessage{
    .message = "Extract to {0s} in {1s} scope",
    .category = "Message",
    .code = "95008",
};
pub const annotate_with_type_from_jsdoc = DiagnosticMessage{
    .message = "Annotate with type from JSDoc",
    .category = "Message",
    .code = "95009",
};
pub const infer_type_of_ARG_from_usage = DiagnosticMessage{
    .message = "Infer type of '{0s}' from usage",
    .category = "Message",
    .code = "95011",
};
pub const infer_parameter_types_from_usage = DiagnosticMessage{
    .message = "Infer parameter types from usage",
    .category = "Message",
    .code = "95012",
};
pub const convert_to_default_import = DiagnosticMessage{
    .message = "Convert to default import",
    .category = "Message",
    .code = "95013",
};
pub const install_ARG = DiagnosticMessage{
    .message = "Install '{0s}'",
    .category = "Message",
    .code = "95014",
};
pub const replace_import_with_ARG = DiagnosticMessage{
    .message = "Replace import with '{0s}'.",
    .category = "Message",
    .code = "95015",
};
pub const use_synthetic_default_member = DiagnosticMessage{
    .message = "Use synthetic 'default' member.",
    .category = "Message",
    .code = "95016",
};
pub const convert_to_es_module = DiagnosticMessage{
    .message = "Convert to ES module",
    .category = "Message",
    .code = "95017",
};
pub const add_undefined_type_to_property_ARG = DiagnosticMessage{
    .message = "Add 'undefined' type to property '{0s}'",
    .category = "Message",
    .code = "95018",
};
pub const add_initializer_to_property_ARG = DiagnosticMessage{
    .message = "Add initializer to property '{0s}'",
    .category = "Message",
    .code = "95019",
};
pub const add_definite_assignment_assertion_to_property_ARG = DiagnosticMessage{
    .message = "Add definite assignment assertion to property '{0s}'",
    .category = "Message",
    .code = "95020",
};
pub const convert_all_type_literals_to_mapped_type = DiagnosticMessage{
    .message = "Convert all type literals to mapped type",
    .category = "Message",
    .code = "95021",
};
pub const add_all_missing_members = DiagnosticMessage{
    .message = "Add all missing members",
    .category = "Message",
    .code = "95022",
};
pub const infer_all_types_from_usage = DiagnosticMessage{
    .message = "Infer all types from usage",
    .category = "Message",
    .code = "95023",
};
pub const delete_all_unused_declarations = DiagnosticMessage{
    .message = "Delete all unused declarations",
    .category = "Message",
    .code = "95024",
};
pub const prefix_all_unused_declarations_with_where_possible = DiagnosticMessage{
    .message = "Prefix all unused declarations with '_' where possible",
    .category = "Message",
    .code = "95025",
};
pub const fix_all_detected_spelling_errors = DiagnosticMessage{
    .message = "Fix all detected spelling errors",
    .category = "Message",
    .code = "95026",
};
pub const add_initializers_to_all_uninitialized_properties = DiagnosticMessage{
    .message = "Add initializers to all uninitialized properties",
    .category = "Message",
    .code = "95027",
};
pub const add_definite_assignment_assertions_to_all_uninitialized_properties = DiagnosticMessage{
    .message = "Add definite assignment assertions to all uninitialized properties",
    .category = "Message",
    .code = "95028",
};
pub const add_undefined_type_to_all_uninitialized_properties = DiagnosticMessage{
    .message = "Add undefined type to all uninitialized properties",
    .category = "Message",
    .code = "95029",
};
pub const change_all_jsdoc_style_types_to_typescript = DiagnosticMessage{
    .message = "Change all jsdoc-style types to TypeScript",
    .category = "Message",
    .code = "95030",
};
pub const change_all_jsdoc_style_types_to_typescript_and_add_undefined_to_nullable_types = DiagnosticMessage{
    .message = "Change all jsdoc-style types to TypeScript (and add '| undefined' to nullable types)",
    .category = "Message",
    .code = "95031",
};
pub const implement_all_unimplemented_interfaces = DiagnosticMessage{
    .message = "Implement all unimplemented interfaces",
    .category = "Message",
    .code = "95032",
};
pub const install_all_missing_types_packages = DiagnosticMessage{
    .message = "Install all missing types packages",
    .category = "Message",
    .code = "95033",
};
pub const rewrite_all_as_indexed_access_types = DiagnosticMessage{
    .message = "Rewrite all as indexed access types",
    .category = "Message",
    .code = "95034",
};
pub const convert_all_to_default_imports = DiagnosticMessage{
    .message = "Convert all to default imports",
    .category = "Message",
    .code = "95035",
};
pub const make_all_super_calls_the_first_statement_in_their_constructor = DiagnosticMessage{
    .message = "Make all 'super()' calls the first statement in their constructor",
    .category = "Message",
    .code = "95036",
};
pub const add_qualifier_to_all_unresolved_variables_matching_a_member_name = DiagnosticMessage{
    .message = "Add qualifier to all unresolved variables matching a member name",
    .category = "Message",
    .code = "95037",
};
pub const change_all_extended_interfaces_to_implements = DiagnosticMessage{
    .message = "Change all extended interfaces to 'implements'",
    .category = "Message",
    .code = "95038",
};
pub const add_all_missing_super_calls = DiagnosticMessage{
    .message = "Add all missing super calls",
    .category = "Message",
    .code = "95039",
};
pub const implement_all_inherited_abstract_classes = DiagnosticMessage{
    .message = "Implement all inherited abstract classes",
    .category = "Message",
    .code = "95040",
};
pub const add_all_missing_async_modifiers = DiagnosticMessage{
    .message = "Add all missing 'async' modifiers",
    .category = "Message",
    .code = "95041",
};
pub const add_ts_ignore_to_all_error_messages = DiagnosticMessage{
    .message = "Add '@ts-ignore' to all error messages",
    .category = "Message",
    .code = "95042",
};
pub const annotate_everything_with_types_from_jsdoc = DiagnosticMessage{
    .message = "Annotate everything with types from JSDoc",
    .category = "Message",
    .code = "95043",
};
pub const add_to_all_uncalled_decorators = DiagnosticMessage{
    .message = "Add '()' to all uncalled decorators",
    .category = "Message",
    .code = "95044",
};
pub const convert_all_constructor_functions_to_classes = DiagnosticMessage{
    .message = "Convert all constructor functions to classes",
    .category = "Message",
    .code = "95045",
};
pub const generate_get_and_set_accessors = DiagnosticMessage{
    .message = "Generate 'get' and 'set' accessors",
    .category = "Message",
    .code = "95046",
};
pub const convert_require_to_import = DiagnosticMessage{
    .message = "Convert 'require' to 'import'",
    .category = "Message",
    .code = "95047",
};
pub const convert_all_require_to_import = DiagnosticMessage{
    .message = "Convert all 'require' to 'import'",
    .category = "Message",
    .code = "95048",
};
pub const move_to_a_new_file = DiagnosticMessage{
    .message = "Move to a new file",
    .category = "Message",
    .code = "95049",
};
pub const remove_unreachable_code = DiagnosticMessage{
    .message = "Remove unreachable code",
    .category = "Message",
    .code = "95050",
};
pub const remove_all_unreachable_code = DiagnosticMessage{
    .message = "Remove all unreachable code",
    .category = "Message",
    .code = "95051",
};
pub const add_missing_typeof = DiagnosticMessage{
    .message = "Add missing 'typeof'",
    .category = "Message",
    .code = "95052",
};
pub const remove_unused_label = DiagnosticMessage{
    .message = "Remove unused label",
    .category = "Message",
    .code = "95053",
};
pub const remove_all_unused_labels = DiagnosticMessage{
    .message = "Remove all unused labels",
    .category = "Message",
    .code = "95054",
};
pub const convert_ARG_to_mapped_object_type = DiagnosticMessage{
    .message = "Convert '{0s}' to mapped object type",
    .category = "Message",
    .code = "95055",
};
pub const convert_namespace_import_to_named_imports = DiagnosticMessage{
    .message = "Convert namespace import to named imports",
    .category = "Message",
    .code = "95056",
};
pub const convert_named_imports_to_namespace_import = DiagnosticMessage{
    .message = "Convert named imports to namespace import",
    .category = "Message",
    .code = "95057",
};
pub const add_or_remove_braces_in_an_arrow_function = DiagnosticMessage{
    .message = "Add or remove braces in an arrow function",
    .category = "Message",
    .code = "95058",
};
pub const add_braces_to_arrow_function = DiagnosticMessage{
    .message = "Add braces to arrow function",
    .category = "Message",
    .code = "95059",
};
pub const remove_braces_from_arrow_function = DiagnosticMessage{
    .message = "Remove braces from arrow function",
    .category = "Message",
    .code = "95060",
};
pub const convert_default_export_to_named_export = DiagnosticMessage{
    .message = "Convert default export to named export",
    .category = "Message",
    .code = "95061",
};
pub const convert_named_export_to_default_export = DiagnosticMessage{
    .message = "Convert named export to default export",
    .category = "Message",
    .code = "95062",
};
pub const add_missing_enum_member_ARG = DiagnosticMessage{
    .message = "Add missing enum member '{0s}'",
    .category = "Message",
    .code = "95063",
};
pub const add_all_missing_imports = DiagnosticMessage{
    .message = "Add all missing imports",
    .category = "Message",
    .code = "95064",
};
pub const convert_to_async_function = DiagnosticMessage{
    .message = "Convert to async function",
    .category = "Message",
    .code = "95065",
};
pub const convert_all_to_async_functions = DiagnosticMessage{
    .message = "Convert all to async functions",
    .category = "Message",
    .code = "95066",
};
pub const add_missing_call_parentheses = DiagnosticMessage{
    .message = "Add missing call parentheses",
    .category = "Message",
    .code = "95067",
};
pub const add_all_missing_call_parentheses = DiagnosticMessage{
    .message = "Add all missing call parentheses",
    .category = "Message",
    .code = "95068",
};
pub const add_unknown_conversion_for_non_overlapping_types = DiagnosticMessage{
    .message = "Add 'unknown' conversion for non-overlapping types",
    .category = "Message",
    .code = "95069",
};
pub const add_unknown_to_all_conversions_of_non_overlapping_types = DiagnosticMessage{
    .message = "Add 'unknown' to all conversions of non-overlapping types",
    .category = "Message",
    .code = "95070",
};
pub const add_missing_new_operator_to_call = DiagnosticMessage{
    .message = "Add missing 'new' operator to call",
    .category = "Message",
    .code = "95071",
};
pub const add_missing_new_operator_to_all_calls = DiagnosticMessage{
    .message = "Add missing 'new' operator to all calls",
    .category = "Message",
    .code = "95072",
};
pub const add_names_to_all_parameters_without_names = DiagnosticMessage{
    .message = "Add names to all parameters without names",
    .category = "Message",
    .code = "95073",
};
pub const enable_the_experimentaldecorators_option_in_your_configuration_file = DiagnosticMessage{
    .message = "Enable the 'experimentalDecorators' option in your configuration file",
    .category = "Message",
    .code = "95074",
};
pub const convert_parameters_to_destructured_object = DiagnosticMessage{
    .message = "Convert parameters to destructured object",
    .category = "Message",
    .code = "95075",
};
pub const extract_type = DiagnosticMessage{
    .message = "Extract type",
    .category = "Message",
    .code = "95077",
};
pub const extract_to_type_alias = DiagnosticMessage{
    .message = "Extract to type alias",
    .category = "Message",
    .code = "95078",
};
pub const extract_to_typedef = DiagnosticMessage{
    .message = "Extract to typedef",
    .category = "Message",
    .code = "95079",
};
pub const infer_this_type_of_ARG_from_usage = DiagnosticMessage{
    .message = "Infer 'this' type of '{0s}' from usage",
    .category = "Message",
    .code = "95080",
};
pub const add_const_to_unresolved_variable = DiagnosticMessage{
    .message = "Add 'const' to unresolved variable",
    .category = "Message",
    .code = "95081",
};
pub const add_const_to_all_unresolved_variables = DiagnosticMessage{
    .message = "Add 'const' to all unresolved variables",
    .category = "Message",
    .code = "95082",
};
pub const add_await = DiagnosticMessage{
    .message = "Add 'await'",
    .category = "Message",
    .code = "95083",
};
pub const add_await_to_initializer_for_ARG = DiagnosticMessage{
    .message = "Add 'await' to initializer for '{0s}'",
    .category = "Message",
    .code = "95084",
};
pub const fix_all_expressions_possibly_missing_await = DiagnosticMessage{
    .message = "Fix all expressions possibly missing 'await'",
    .category = "Message",
    .code = "95085",
};
pub const remove_unnecessary_await = DiagnosticMessage{
    .message = "Remove unnecessary 'await'",
    .category = "Message",
    .code = "95086",
};
pub const remove_all_unnecessary_uses_of_await = DiagnosticMessage{
    .message = "Remove all unnecessary uses of 'await'",
    .category = "Message",
    .code = "95087",
};
pub const enable_the_jsx_flag_in_your_configuration_file = DiagnosticMessage{
    .message = "Enable the '--jsx' flag in your configuration file",
    .category = "Message",
    .code = "95088",
};
pub const add_await_to_initializers = DiagnosticMessage{
    .message = "Add 'await' to initializers",
    .category = "Message",
    .code = "95089",
};
pub const extract_to_interface = DiagnosticMessage{
    .message = "Extract to interface",
    .category = "Message",
    .code = "95090",
};
pub const convert_to_a_bigint_numeric_literal = DiagnosticMessage{
    .message = "Convert to a bigint numeric literal",
    .category = "Message",
    .code = "95091",
};
pub const convert_all_to_bigint_numeric_literals = DiagnosticMessage{
    .message = "Convert all to bigint numeric literals",
    .category = "Message",
    .code = "95092",
};
pub const convert_const_to_let = DiagnosticMessage{
    .message = "Convert 'const' to 'let'",
    .category = "Message",
    .code = "95093",
};
pub const prefix_with_declare = DiagnosticMessage{
    .message = "Prefix with 'declare'",
    .category = "Message",
    .code = "95094",
};
pub const prefix_all_incorrect_property_declarations_with_declare = DiagnosticMessage{
    .message = "Prefix all incorrect property declarations with 'declare'",
    .category = "Message",
    .code = "95095",
};
pub const convert_to_template_string = DiagnosticMessage{
    .message = "Convert to template string",
    .category = "Message",
    .code = "95096",
};
pub const add_export_ARG_to_make_this_file_into_a_module = DiagnosticMessage{
    .message = "Add 'export {{}' to make this file into a module",
    .category = "Message",
    .code = "95097",
};
pub const set_the_target_option_in_your_configuration_file_to_ARG = DiagnosticMessage{
    .message = "Set the 'target' option in your configuration file to '{0s}'",
    .category = "Message",
    .code = "95098",
};
pub const set_the_module_option_in_your_configuration_file_to_ARG = DiagnosticMessage{
    .message = "Set the 'module' option in your configuration file to '{0s}'",
    .category = "Message",
    .code = "95099",
};
pub const convert_invalid_character_to_its_html_entity_code = DiagnosticMessage{
    .message = "Convert invalid character to its html entity code",
    .category = "Message",
    .code = "95100",
};
pub const convert_all_invalid_characters_to_html_entity_code = DiagnosticMessage{
    .message = "Convert all invalid characters to HTML entity code",
    .category = "Message",
    .code = "95101",
};
pub const convert_all_const_to_let = DiagnosticMessage{
    .message = "Convert all 'const' to 'let'",
    .category = "Message",
    .code = "95102",
};
pub const convert_function_expression_ARG_to_arrow_function = DiagnosticMessage{
    .message = "Convert function expression '{0s}' to arrow function",
    .category = "Message",
    .code = "95105",
};
pub const convert_function_declaration_ARG_to_arrow_function = DiagnosticMessage{
    .message = "Convert function declaration '{0s}' to arrow function",
    .category = "Message",
    .code = "95106",
};
pub const fix_all_implicit_this_errors = DiagnosticMessage{
    .message = "Fix all implicit-'this' errors",
    .category = "Message",
    .code = "95107",
};
pub const wrap_invalid_character_in_an_expression_container = DiagnosticMessage{
    .message = "Wrap invalid character in an expression container",
    .category = "Message",
    .code = "95108",
};
pub const wrap_all_invalid_characters_in_an_expression_container = DiagnosticMessage{
    .message = "Wrap all invalid characters in an expression container",
    .category = "Message",
    .code = "95109",
};
pub const visit_https_aka_ms_tsconfig_to_read_more_about_this_file = DiagnosticMessage{
    .message = "Visit https://aka.ms/tsconfig to read more about this file",
    .category = "Message",
    .code = "95110",
};
pub const add_a_return_statement = DiagnosticMessage{
    .message = "Add a return statement",
    .category = "Message",
    .code = "95111",
};
pub const remove_braces_from_arrow_function_body = DiagnosticMessage{
    .message = "Remove braces from arrow function body",
    .category = "Message",
    .code = "95112",
};
pub const wrap_the_following_body_with_parentheses_which_should_be_an_object_literal = DiagnosticMessage{
    .message = "Wrap the following body with parentheses which should be an object literal",
    .category = "Message",
    .code = "95113",
};
pub const add_all_missing_return_statement = DiagnosticMessage{
    .message = "Add all missing return statement",
    .category = "Message",
    .code = "95114",
};
pub const remove_braces_from_all_arrow_function_bodies_with_relevant_issues = DiagnosticMessage{
    .message = "Remove braces from all arrow function bodies with relevant issues",
    .category = "Message",
    .code = "95115",
};
pub const wrap_all_object_literal_with_parentheses = DiagnosticMessage{
    .message = "Wrap all object literal with parentheses",
    .category = "Message",
    .code = "95116",
};
pub const move_labeled_tuple_element_modifiers_to_labels = DiagnosticMessage{
    .message = "Move labeled tuple element modifiers to labels",
    .category = "Message",
    .code = "95117",
};
pub const convert_overload_list_to_single_signature = DiagnosticMessage{
    .message = "Convert overload list to single signature",
    .category = "Message",
    .code = "95118",
};
pub const generate_get_and_set_accessors_for_all_overriding_properties = DiagnosticMessage{
    .message = "Generate 'get' and 'set' accessors for all overriding properties",
    .category = "Message",
    .code = "95119",
};
pub const wrap_in_jsx_fragment = DiagnosticMessage{
    .message = "Wrap in JSX fragment",
    .category = "Message",
    .code = "95120",
};
pub const wrap_all_unparented_jsx_in_jsx_fragment = DiagnosticMessage{
    .message = "Wrap all unparented JSX in JSX fragment",
    .category = "Message",
    .code = "95121",
};
pub const convert_arrow_function_or_function_expression = DiagnosticMessage{
    .message = "Convert arrow function or function expression",
    .category = "Message",
    .code = "95122",
};
pub const convert_to_anonymous_function = DiagnosticMessage{
    .message = "Convert to anonymous function",
    .category = "Message",
    .code = "95123",
};
pub const convert_to_named_function = DiagnosticMessage{
    .message = "Convert to named function",
    .category = "Message",
    .code = "95124",
};
pub const convert_to_arrow_function = DiagnosticMessage{
    .message = "Convert to arrow function",
    .category = "Message",
    .code = "95125",
};
pub const remove_parentheses = DiagnosticMessage{
    .message = "Remove parentheses",
    .category = "Message",
    .code = "95126",
};
pub const could_not_find_a_containing_arrow_function = DiagnosticMessage{
    .message = "Could not find a containing arrow function",
    .category = "Message",
    .code = "95127",
};
pub const containing_function_is_not_an_arrow_function = DiagnosticMessage{
    .message = "Containing function is not an arrow function",
    .category = "Message",
    .code = "95128",
};
pub const could_not_find_export_statement = DiagnosticMessage{
    .message = "Could not find export statement",
    .category = "Message",
    .code = "95129",
};
pub const this_file_already_has_a_default_export = DiagnosticMessage{
    .message = "This file already has a default export",
    .category = "Message",
    .code = "95130",
};
pub const could_not_find_import_clause = DiagnosticMessage{
    .message = "Could not find import clause",
    .category = "Message",
    .code = "95131",
};
pub const could_not_find_namespace_import_or_named_imports = DiagnosticMessage{
    .message = "Could not find namespace import or named imports",
    .category = "Message",
    .code = "95132",
};
pub const selection_is_not_a_valid_type_node = DiagnosticMessage{
    .message = "Selection is not a valid type node",
    .category = "Message",
    .code = "95133",
};
pub const no_type_could_be_extracted_from_this_type_node = DiagnosticMessage{
    .message = "No type could be extracted from this type node",
    .category = "Message",
    .code = "95134",
};
pub const could_not_find_property_for_which_to_generate_accessor = DiagnosticMessage{
    .message = "Could not find property for which to generate accessor",
    .category = "Message",
    .code = "95135",
};
pub const name_is_not_valid = DiagnosticMessage{
    .message = "Name is not valid",
    .category = "Message",
    .code = "95136",
};
pub const can_only_convert_property_with_modifier = DiagnosticMessage{
    .message = "Can only convert property with modifier",
    .category = "Message",
    .code = "95137",
};
pub const switch_each_misused_ARG_to_ARG = DiagnosticMessage{
    .message = "Switch each misused '{0s}' to '{1s}'",
    .category = "Message",
    .code = "95138",
};
pub const convert_to_optional_chain_expression = DiagnosticMessage{
    .message = "Convert to optional chain expression",
    .category = "Message",
    .code = "95139",
};
pub const could_not_find_convertible_access_expression = DiagnosticMessage{
    .message = "Could not find convertible access expression",
    .category = "Message",
    .code = "95140",
};
pub const could_not_find_matching_access_expressions = DiagnosticMessage{
    .message = "Could not find matching access expressions",
    .category = "Message",
    .code = "95141",
};
pub const can_only_convert_logical_and_access_chains = DiagnosticMessage{
    .message = "Can only convert logical AND access chains",
    .category = "Message",
    .code = "95142",
};
pub const add_void_to_promise_resolved_without_a_value = DiagnosticMessage{
    .message = "Add 'void' to Promise resolved without a value",
    .category = "Message",
    .code = "95143",
};
pub const add_void_to_all_promises_resolved_without_a_value = DiagnosticMessage{
    .message = "Add 'void' to all Promises resolved without a value",
    .category = "Message",
    .code = "95144",
};
pub const use_element_access_for_ARG = DiagnosticMessage{
    .message = "Use element access for '{0s}'",
    .category = "Message",
    .code = "95145",
};
pub const use_element_access_for_all_undeclared_properties = DiagnosticMessage{
    .message = "Use element access for all undeclared properties.",
    .category = "Message",
    .code = "95146",
};
pub const delete_all_unused_imports = DiagnosticMessage{
    .message = "Delete all unused imports",
    .category = "Message",
    .code = "95147",
};
pub const infer_function_return_type = DiagnosticMessage{
    .message = "Infer function return type",
    .category = "Message",
    .code = "95148",
};
pub const return_type_must_be_inferred_from_a_function = DiagnosticMessage{
    .message = "Return type must be inferred from a function",
    .category = "Message",
    .code = "95149",
};
pub const could_not_determine_function_return_type = DiagnosticMessage{
    .message = "Could not determine function return type",
    .category = "Message",
    .code = "95150",
};
pub const could_not_convert_to_arrow_function = DiagnosticMessage{
    .message = "Could not convert to arrow function",
    .category = "Message",
    .code = "95151",
};
pub const could_not_convert_to_named_function = DiagnosticMessage{
    .message = "Could not convert to named function",
    .category = "Message",
    .code = "95152",
};
pub const could_not_convert_to_anonymous_function = DiagnosticMessage{
    .message = "Could not convert to anonymous function",
    .category = "Message",
    .code = "95153",
};
pub const can_only_convert_string_concatenations_and_string_literals = DiagnosticMessage{
    .message = "Can only convert string concatenations and string literals",
    .category = "Message",
    .code = "95154",
};
pub const selection_is_not_a_valid_statement_or_statements = DiagnosticMessage{
    .message = "Selection is not a valid statement or statements",
    .category = "Message",
    .code = "95155",
};
pub const add_missing_function_declaration_ARG = DiagnosticMessage{
    .message = "Add missing function declaration '{0s}'",
    .category = "Message",
    .code = "95156",
};
pub const add_all_missing_function_declarations = DiagnosticMessage{
    .message = "Add all missing function declarations",
    .category = "Message",
    .code = "95157",
};
pub const method_not_implemented = DiagnosticMessage{
    .message = "Method not implemented.",
    .category = "Message",
    .code = "95158",
};
pub const function_not_implemented = DiagnosticMessage{
    .message = "Function not implemented.",
    .category = "Message",
    .code = "95159",
};
pub const add_override_modifier = DiagnosticMessage{
    .message = "Add 'override' modifier",
    .category = "Message",
    .code = "95160",
};
pub const remove_override_modifier = DiagnosticMessage{
    .message = "Remove 'override' modifier",
    .category = "Message",
    .code = "95161",
};
pub const add_all_missing_override_modifiers = DiagnosticMessage{
    .message = "Add all missing 'override' modifiers",
    .category = "Message",
    .code = "95162",
};
pub const remove_all_unnecessary_override_modifiers = DiagnosticMessage{
    .message = "Remove all unnecessary 'override' modifiers",
    .category = "Message",
    .code = "95163",
};
pub const can_only_convert_named_export = DiagnosticMessage{
    .message = "Can only convert named export",
    .category = "Message",
    .code = "95164",
};
pub const add_missing_properties = DiagnosticMessage{
    .message = "Add missing properties",
    .category = "Message",
    .code = "95165",
};
pub const add_all_missing_properties = DiagnosticMessage{
    .message = "Add all missing properties",
    .category = "Message",
    .code = "95166",
};
pub const add_missing_attributes = DiagnosticMessage{
    .message = "Add missing attributes",
    .category = "Message",
    .code = "95167",
};
pub const add_all_missing_attributes = DiagnosticMessage{
    .message = "Add all missing attributes",
    .category = "Message",
    .code = "95168",
};
pub const add_undefined_to_optional_property_type = DiagnosticMessage{
    .message = "Add 'undefined' to optional property type",
    .category = "Message",
    .code = "95169",
};
pub const convert_named_imports_to_default_import = DiagnosticMessage{
    .message = "Convert named imports to default import",
    .category = "Message",
    .code = "95170",
};
pub const delete_unused_param_tag_ARG = DiagnosticMessage{
    .message = "Delete unused '@param' tag '{0s}'",
    .category = "Message",
    .code = "95171",
};
pub const delete_all_unused_param_tags = DiagnosticMessage{
    .message = "Delete all unused '@param' tags",
    .category = "Message",
    .code = "95172",
};
pub const rename_param_tag_name_ARG_to_ARG = DiagnosticMessage{
    .message = "Rename '@param' tag name '{0s}' to '{1s}'",
    .category = "Message",
    .code = "95173",
};
pub const use_ARG = DiagnosticMessage{
    .message = "Use `{0s}`.",
    .category = "Message",
    .code = "95174",
};
pub const use_number_isnan_in_all_conditions = DiagnosticMessage{
    .message = "Use `Number.isNaN` in all conditions.",
    .category = "Message",
    .code = "95175",
};
pub const convert_typedef_to_typescript_type = DiagnosticMessage{
    .message = "Convert typedef to TypeScript type.",
    .category = "Message",
    .code = "95176",
};
pub const convert_all_typedef_to_typescript_types = DiagnosticMessage{
    .message = "Convert all typedef to TypeScript types.",
    .category = "Message",
    .code = "95177",
};
pub const move_to_file = DiagnosticMessage{
    .message = "Move to file",
    .category = "Message",
    .code = "95178",
};
pub const cannot_move_to_file_selected_file_is_invalid = DiagnosticMessage{
    .message = "Cannot move to file, selected file is invalid",
    .category = "Message",
    .code = "95179",
};
pub const use_import_type = DiagnosticMessage{
    .message = "Use 'import type'",
    .category = "Message",
    .code = "95180",
};
pub const use_type_ARG = DiagnosticMessage{
    .message = "Use 'type {0s}'",
    .category = "Message",
    .code = "95181",
};
pub const fix_all_with_type_only_imports = DiagnosticMessage{
    .message = "Fix all with type-only imports",
    .category = "Message",
    .code = "95182",
};
pub const cannot_move_statements_to_the_selected_file = DiagnosticMessage{
    .message = "Cannot move statements to the selected file",
    .category = "Message",
    .code = "95183",
};
pub const inline_variable = DiagnosticMessage{
    .message = "Inline variable",
    .category = "Message",
    .code = "95184",
};
pub const could_not_find_variable_to_inline = DiagnosticMessage{
    .message = "Could not find variable to inline.",
    .category = "Message",
    .code = "95185",
};
pub const variables_with_multiple_declarations_cannot_be_inlined = DiagnosticMessage{
    .message = "Variables with multiple declarations cannot be inlined.",
    .category = "Message",
    .code = "95186",
};
pub const add_missing_comma_for_object_member_completion_ARG = DiagnosticMessage{
    .message = "Add missing comma for object member completion '{0s}'.",
    .category = "Message",
    .code = "95187",
};
pub const add_missing_parameter_to_ARG = DiagnosticMessage{
    .message = "Add missing parameter to '{0s}'",
    .category = "Message",
    .code = "95188",
};
pub const add_missing_parameters_to_ARG = DiagnosticMessage{
    .message = "Add missing parameters to '{0s}'",
    .category = "Message",
    .code = "95189",
};
pub const add_all_missing_parameters = DiagnosticMessage{
    .message = "Add all missing parameters",
    .category = "Message",
    .code = "95190",
};
pub const add_optional_parameter_to_ARG = DiagnosticMessage{
    .message = "Add optional parameter to '{0s}'",
    .category = "Message",
    .code = "95191",
};
pub const add_optional_parameters_to_ARG = DiagnosticMessage{
    .message = "Add optional parameters to '{0s}'",
    .category = "Message",
    .code = "95192",
};
pub const add_all_optional_parameters = DiagnosticMessage{
    .message = "Add all optional parameters",
    .category = "Message",
    .code = "95193",
};
pub const wrap_in_parentheses = DiagnosticMessage{
    .message = "Wrap in parentheses",
    .category = "Message",
    .code = "95194",
};
pub const wrap_all_invalid_decorator_expressions_in_parentheses = DiagnosticMessage{
    .message = "Wrap all invalid decorator expressions in parentheses",
    .category = "Message",
    .code = "95195",
};
pub const no_value_exists_in_scope_for_the_shorthand_property_ARG_either_declare_one_or_provide_an_initializer = DiagnosticMessage{
    .message = "No value exists in scope for the shorthand property '{0s}'. Either declare one or provide an initializer.",
    .category = "Error",
    .code = "18004",
};
pub const classes_may_not_have_a_field_named_constructor = DiagnosticMessage{
    .message = "Classes may not have a field named 'constructor'.",
    .category = "Error",
    .code = "18006",
};
pub const jsx_expressions_may_not_use_the_comma_operator_did_you_mean_to_write_an_array = DiagnosticMessage{
    .message = "JSX expressions may not use the comma operator. Did you mean to write an array?",
    .category = "Error",
    .code = "18007",
};
pub const private_identifiers_cannot_be_used_as_parameters = DiagnosticMessage{
    .message = "Private identifiers cannot be used as parameters.",
    .category = "Error",
    .code = "18009",
};
pub const an_accessibility_modifier_cannot_be_used_with_a_private_identifier = DiagnosticMessage{
    .message = "An accessibility modifier cannot be used with a private identifier.",
    .category = "Error",
    .code = "18010",
};
pub const the_operand_of_a_delete_operator_cannot_be_a_private_identifier = DiagnosticMessage{
    .message = "The operand of a 'delete' operator cannot be a private identifier.",
    .category = "Error",
    .code = "18011",
};
pub const constructor_is_a_reserved_word = DiagnosticMessage{
    .message = "'#constructor' is a reserved word.",
    .category = "Error",
    .code = "18012",
};
pub const property_ARG_is_not_accessible_outside_class_ARG_because_it_has_a_private_identifier = DiagnosticMessage{
    .message = "Property '{0s}' is not accessible outside class '{1s}' because it has a private identifier.",
    .category = "Error",
    .code = "18013",
};
pub const the_property_ARG_cannot_be_accessed_on_type_ARG_within_this_class_because_it_is_shadowed_by_another_private_identifier_with_the_same_spelling = DiagnosticMessage{
    .message = "The property '{0s}' cannot be accessed on type '{1s}' within this class because it is shadowed by another private identifier with the same spelling.",
    .category = "Error",
    .code = "18014",
};
pub const property_ARG_in_type_ARG_refers_to_a_different_member_that_cannot_be_accessed_from_within_type_ARG = DiagnosticMessage{
    .message = "Property '{0s}' in type '{1s}' refers to a different member that cannot be accessed from within type '{2s}'.",
    .category = "Error",
    .code = "18015",
};
pub const private_identifiers_are_not_allowed_outside_class_bodies = DiagnosticMessage{
    .message = "Private identifiers are not allowed outside class bodies.",
    .category = "Error",
    .code = "18016",
};
pub const the_shadowing_declaration_of_ARG_is_defined_here = DiagnosticMessage{
    .message = "The shadowing declaration of '{0s}' is defined here",
    .category = "Error",
    .code = "18017",
};
pub const the_declaration_of_ARG_that_you_probably_intended_to_use_is_defined_here = DiagnosticMessage{
    .message = "The declaration of '{0s}' that you probably intended to use is defined here",
    .category = "Error",
    .code = "18018",
};
pub const ARG_modifier_cannot_be_used_with_a_private_identifier = DiagnosticMessage{
    .message = "'{0s}' modifier cannot be used with a private identifier.",
    .category = "Error",
    .code = "18019",
};
pub const an_enum_member_cannot_be_named_with_a_private_identifier = DiagnosticMessage{
    .message = "An enum member cannot be named with a private identifier.",
    .category = "Error",
    .code = "18024",
};
pub const can_only_be_used_at_the_start_of_a_file = DiagnosticMessage{
    .message = "'#!' can only be used at the start of a file.",
    .category = "Error",
    .code = "18026",
};
pub const compiler_reserves_name_ARG_when_emitting_private_identifier_downlevel = DiagnosticMessage{
    .message = "Compiler reserves name '{0s}' when emitting private identifier downlevel.",
    .category = "Error",
    .code = "18027",
};
pub const private_identifiers_are_only_available_when_targeting_ecmascript_2015_and_higher = DiagnosticMessage{
    .message = "Private identifiers are only available when targeting ECMAScript 2015 and higher.",
    .category = "Error",
    .code = "18028",
};
pub const private_identifiers_are_not_allowed_in_variable_declarations = DiagnosticMessage{
    .message = "Private identifiers are not allowed in variable declarations.",
    .category = "Error",
    .code = "18029",
};
pub const an_optional_chain_cannot_contain_private_identifiers = DiagnosticMessage{
    .message = "An optional chain cannot contain private identifiers.",
    .category = "Error",
    .code = "18030",
};
pub const the_intersection_ARG_was_reduced_to_never_because_property_ARG_has_conflicting_types_in_some_constituents = DiagnosticMessage{
    .message = "The intersection '{0s}' was reduced to 'never' because property '{1s}' has conflicting types in some constituents.",
    .category = "Error",
    .code = "18031",
};
pub const the_intersection_ARG_was_reduced_to_never_because_property_ARG_exists_in_multiple_constituents_and_is_private_in_some = DiagnosticMessage{
    .message = "The intersection '{0s}' was reduced to 'never' because property '{1s}' exists in multiple constituents and is private in some.",
    .category = "Error",
    .code = "18032",
};
pub const type_ARG_is_not_assignable_to_type_ARG_as_required_for_computed_enum_member_values = DiagnosticMessage{
    .message = "Type '{0s}' is not assignable to type '{1s}' as required for computed enum member values.",
    .category = "Error",
    .code = "18033",
};
pub const specify_the_jsx_fragment_factory_function_to_use_when_targeting_react_jsx_emit_with_jsxfactory_compiler_option_is_specified_e_g_fragment = DiagnosticMessage{
    .message = "Specify the JSX fragment factory function to use when targeting 'react' JSX emit with 'jsxFactory' compiler option is specified, e.g. 'Fragment'.",
    .category = "Message",
    .code = "18034",
};
pub const invalid_value_for_jsxfragmentfactory_ARG_is_not_a_valid_identifier_or_qualified_name = DiagnosticMessage{
    .message = "Invalid value for 'jsxFragmentFactory'. '{0s}' is not a valid identifier or qualified-name.",
    .category = "Error",
    .code = "18035",
};
pub const class_decorators_can_t_be_used_with_static_private_identifier_consider_removing_the_experimental_decorator = DiagnosticMessage{
    .message = "Class decorators can't be used with static private identifier. Consider removing the experimental decorator.",
    .category = "Error",
    .code = "18036",
};
pub const await_expression_cannot_be_used_inside_a_class_static_block = DiagnosticMessage{
    .message = "'await' expression cannot be used inside a class static block.",
    .category = "Error",
    .code = "18037",
};
pub const for_await_loops_cannot_be_used_inside_a_class_static_block = DiagnosticMessage{
    .message = "'for await' loops cannot be used inside a class static block.",
    .category = "Error",
    .code = "18038",
};
pub const invalid_use_of_ARG_it_cannot_be_used_inside_a_class_static_block = DiagnosticMessage{
    .message = "Invalid use of '{0s}'. It cannot be used inside a class static block.",
    .category = "Error",
    .code = "18039",
};
pub const a_return_statement_cannot_be_used_inside_a_class_static_block = DiagnosticMessage{
    .message = "A 'return' statement cannot be used inside a class static block.",
    .category = "Error",
    .code = "18041",
};
pub const ARG_is_a_type_and_cannot_be_imported_in_javascript_files_use_ARG_in_a_jsdoc_type_annotation = DiagnosticMessage{
    .message = "'{0s}' is a type and cannot be imported in JavaScript files. Use '{1s}' in a JSDoc type annotation.",
    .category = "Error",
    .code = "18042",
};
pub const types_cannot_appear_in_export_declarations_in_javascript_files = DiagnosticMessage{
    .message = "Types cannot appear in export declarations in JavaScript files.",
    .category = "Error",
    .code = "18043",
};
pub const ARG_is_automatically_exported_here = DiagnosticMessage{
    .message = "'{0s}' is automatically exported here.",
    .category = "Message",
    .code = "18044",
};
pub const properties_with_the_accessor_modifier_are_only_available_when_targeting_ecmascript_2015_and_higher = DiagnosticMessage{
    .message = "Properties with the 'accessor' modifier are only available when targeting ECMAScript 2015 and higher.",
    .category = "Error",
    .code = "18045",
};
pub const ARG_is_of_type_unknown = DiagnosticMessage{
    .message = "'{0s}' is of type 'unknown'.",
    .category = "Error",
    .code = "18046",
};
pub const ARG_is_possibly_null = DiagnosticMessage{
    .message = "'{0s}' is possibly 'null'.",
    .category = "Error",
    .code = "18047",
};
pub const ARG_is_possibly_undefined = DiagnosticMessage{
    .message = "'{0s}' is possibly 'undefined'.",
    .category = "Error",
    .code = "18048",
};
pub const ARG_is_possibly_null_or_undefined = DiagnosticMessage{
    .message = "'{0s}' is possibly 'null' or 'undefined'.",
    .category = "Error",
    .code = "18049",
};
pub const the_value_ARG_cannot_be_used_here = DiagnosticMessage{
    .message = "The value '{0s}' cannot be used here.",
    .category = "Error",
    .code = "18050",
};
pub const compiler_option_ARG_cannot_be_given_an_empty_string = DiagnosticMessage{
    .message = "Compiler option '{0s}' cannot be given an empty string.",
    .category = "Error",
    .code = "18051",
};
pub const its_type_ARG_is_not_a_valid_jsx_element_type = DiagnosticMessage{
    .message = "Its type '{0s}' is not a valid JSX element type.",
    .category = "Error",
    .code = "18053",
};
pub const await_using_statements_cannot_be_used_inside_a_class_static_block = DiagnosticMessage{
    .message = "'await using' statements cannot be used inside a class static block.",
    .category = "Error",
    .code = "18054",
};
pub const ARG_has_a_string_type_but_must_have_syntactically_recognizable_string_syntax_when_isolatedmodules_is_enabled = DiagnosticMessage{
    .message = "'{0s}' has a string type, but must have syntactically recognizable string syntax when 'isolatedModules' is enabled.",
    .category = "Error",
    .code = "18055",
};
pub const enum_member_following_a_non_literal_numeric_member_must_have_an_initializer_when_isolatedmodules_is_enabled = DiagnosticMessage{
    .message = "Enum member following a non-literal numeric member must have an initializer when 'isolatedModules' is enabled.",
    .category = "Error",
    .code = "18056",
};
pub const string_literal_import_and_export_names_are_not_supported_when_the_module_flag_is_set_to_es2015_or_es2020 = DiagnosticMessage{
    .message = "String literal import and export names are not supported when the '--module' flag is set to 'es2015' or 'es2020'.",
    .category = "Error",
    .code = "18057",
};
