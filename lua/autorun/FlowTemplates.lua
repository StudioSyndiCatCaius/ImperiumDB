local a={}

a['dialogue']={
    name="Dialogue",

    nodes={
        'node_DialogueLine',
        'node_luaIf',
        'node_luaScript',
    }
}

a['quest']={
    name="Quest",

    nodes={
        'q_awaitEvent',
        'q_Dialogue',
        'q_LevelTransit',
        'node_luaIf',
        'node_luaScript',
    }
}

a['chat']={
    name="Chat",

    nodes={
        'node_DialogueLine',
        'node_luaIf',
        'node_luaScript',
    }
}

ImpDB_FlowTemplates=a