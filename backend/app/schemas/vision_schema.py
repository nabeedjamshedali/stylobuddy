from pydantic import BaseModel


class ClothingAnalysis(BaseModel):
    description: str
    category: str
