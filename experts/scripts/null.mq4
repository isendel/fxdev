    if((GlobalVariableGet("BUYSTOP_Price"+Symbol()+Period())-Ask)/Point>MarketInfo(Symbol(),MODE_SPREAD)) {
      open_positions(OP_BUYSTOP, BUYSTOP_Lots_B, GlobalVariableGet("SL_BUYSTOP"+Symbol()+Period()), GlobalVariableGet("TP_BUYSTOP"+Symbol()+Period()), MagicNumber_B, GlobalVariableGet("BUYSTOP_Price"+Symbol()+Period()), "NONE", "муфик купить");
    } else {
      open_positions(OP_BUY, BUYSTOP_Lots_B, GlobalVariableGet("SL_BUYSTOP"+Symbol()+Period()), GlobalVariableGet("TP_BUYSTOP"+Symbol()+Period()), MagicNumber_B, 0.0, "NONE", "муфик купить");
    } 