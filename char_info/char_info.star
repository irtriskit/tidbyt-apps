load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

AUTH_URL = "https://auth-service.dndbeyond.com/v1/cobalt-token"
SIMPLE_CHAR_URL = "https://character-service-scds.dndbeyond.com/v2/characters"

DEFAULT_CHAR_ID = 0
DEFAULT_COBALT_SESSION_TOKEN = ""

def main(config):
    CHAR_ID = int(config.str("characterId",DEFAULT_CHAR_ID))
    COBALT_SESSION_TOKEN = config.str("cobaltSession",DEFAULT_COBALT_SESSION_TOKEN)

    # check for valid config values
    if CHAR_ID == 0:
        return render.Root(
            child = render.WrappedText(
                content="Please provide a valid Character ID",
                width = 64,
            )
        )

    if COBALT_SESSION_TOKEN == "":
        return render.Root(
            child = render.WrappedText(
                content="Please provide a valid Cobalt Session Cookie",
                width = 64,
            )
        )

    # get auth token
    authResponse = http.post(AUTH_URL,headers={"Authorization":"Bearer %s" % COBALT_SESSION_TOKEN}, ttl_seconds = 240) # cache for 4 minutes
    token = authResponse.json()["token"]

    # get character data
    charResponse = http.post(SIMPLE_CHAR_URL,headers={"Authorization":"Bearer %s" % token},json_body={"characterIds":[CHAR_ID]})

    if charResponse.status_code != 200:
        return render.Root(
            child = render.WrappedText(
                content="Error retrieving character: %d" % charResponse.status_code,
                width = 64,
            )
        )

    charData = charResponse.json()["foundCharacters"][0]

    if charData["hitPointInfo"]["current"] > 0:
        return stable(charData)
    else:
        return death_saves(charData)

def stable(charData):
    name = charData["name"]
    nameColor = charData["decorations"]["characterTheme"]["themeColor"]

    backgroundColor = "#000"
    textColor = "#FFF"
    accentTextColor = "#999"

    hitPointInfo = charData["hitPointInfo"]
    currentHp = hitPointInfo["current"]
    maxHp = hitPointInfo["maximum"]
    tempHp = hitPointInfo["temp"]

    return render.Root(
        child = render.Box(
            color = backgroundColor,
            child = render.Column(
                children=[
                    render.Text(
                        content = name,
                        font = "6x13",
                        color = nameColor,
                    ),
                    render.Text(
                        content = "Hit Points",
                        font = "5x8",
                        color = textColor,
                    ),
                    render.Row(
                        children = [
                            render.Column(
                                children = [
                                    render.Text(
                                        content = "Current",
                                        font = "CG-pixel-4x5-mono",
                                        color = accentTextColor,
                                    ),
                                    render.Box(width=1, height=1, color="#000"),
                                    render.Text(
                                        content = "%d/%d" % (currentHp, maxHp),
                                        font = "CG-pixel-4x5-mono",
                                        color = "#0F0",
                                    ),
                                ],
                                cross_align = "end",
                            ),
                            render.Box(width=2, height=1, color="#000"),
                            render.Column(
                                children=[
                                    render.Text(
                                        content = "Temp",
                                        font = "CG-pixel-4x5-mono",
                                        color = accentTextColor,
                                    ),
                                    render.Box(width=1, height=1, color="#000"),
                                    render.Text(
                                        content = "%d" % tempHp,
                                        font = "CG-pixel-4x5-mono",
                                        color = "#FF0",
                                    ),
                                ],
                                cross_align = "end",
                            ),
                        ],  
                    )             
                ],
            )
        )
    )

def death_saves(charData):
    name = charData["name"]
    nameColor = charData["decorations"]["characterTheme"]["themeColor"]

    backgroundColor = "#000"
    textColor = "#FFF"

    deathSaveInfo = charData["deathSaveInfo"]
    failureString = ""
    successString = ""

    for x in range(int(deathSaveInfo["failCount"])):
        failureString += "X"

    for x in range(int(deathSaveInfo["successCount"])):
        successString += "X"

    return render.Root(
        child = render.Box(
            color = backgroundColor,
            child = render.Column(
                children=[
                    render.Text(
                        content = name,
                        font = "6x13",
                        color = nameColor,
                    ),
                    render.Text(
                        content = "Death Saves",
                        font = "5x8",
                        color = textColor,
                    ),
                    render.Row(
                        children=[
                            render.Text(
                                content = "Failure ",
                                font = "CG-pixel-4x5-mono",
                                color = textColor,
                            ),
                            render.Text(
                                content = failureString,
                                font = "CG-pixel-4x5-mono",
                                color = "#F00",
                            ),
                        ],
                        main_align="start"
                    ),
                    render.Box(width=1, height=1, color="#000"),
                    render.Row(
                        children=[
                            render.Text(
                                content = "Success ",
                                font = "CG-pixel-4x5-mono",
                                color = textColor,
                            ),
                            render.Text(
                                content = successString,
                                font = "CG-pixel-4x5-mono",
                                color = "#0F0",
                            ),
                        ]
                    ),                   
                ],
            )
        )
    )
    
def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "characterId",
                name = "Character ID",
                desc = "ID of the character you wish to view from D&D Beyond",
                icon = "user",
            ),
            schema.Text(
                id = "cobaltSession",
                name = "Cobalt Session Cookie",
                desc = "The value of your CobaltSession cookie for D&D Beyond",
                icon = "key",
            ),
        ],
    )
