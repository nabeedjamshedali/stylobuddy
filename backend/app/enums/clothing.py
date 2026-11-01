import enum


class ClothingCategory(str, enum.Enum):
    TOPWEAR = "topwear"
    BOTTOMWEAR = "bottomwear"
    FOOTWEAR = "footwear"
    ACCESSORY = "accessory"
    OUTERWEAR = "outerwear"
    ETHNIC = "ethnic"
