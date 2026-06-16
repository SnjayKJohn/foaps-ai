from sqlalchemy import BigInteger, Column, Float, Integer, String

from app.core.database import Base


class ZomatoItem(Base):
    __tablename__ = "zomato_items"

    id = Column(BigInteger, primary_key=True)
    item_name = Column(String, nullable=False)
    item_short_description = Column(String)
    item_long_description = Column(String)
    item_final_price = Column(Float)
    item_is_active = Column(Integer, default=1)
    item_in_stock = Column(Integer, default=1)
    location_id = Column(BigInteger)
