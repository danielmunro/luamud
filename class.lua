local class = {
  classes = {
    warrior = {
      attr = { str = 2, con = 1, dex = 1, wis = -1, int = -2 }
    },
    thief = {
      attr = { dex = 2, con = 1, str = 1, int = -1, wis = -2 }
    },
    mage = {
      attr = { int = 2, wis = 1, dex = 1, con = -1, str = -2 }
    },
    cleric = {
      attr = { wis = 2, int = 1, con = 1, str = -1, dex = -2 }
    }
  }
}

return class
