from sqlalchemy import BigInteger, Boolean, Column, DateTime, Float, Integer, String, Text

from app.core.database import Base


class ZomatoItemVariant(Base):
    __tablename__ = "zomato_item_variants"

    id = Column(BigInteger, primary_key=True)
    zomato_item_id = Column(Integer)
    name = Column(String)
    description = Column(String)
    unit_price = Column(Integer)
    is_active = Column(Boolean, default=True)
    deleted_at = Column(DateTime)


class ZomatoItemGroup(Base):
    __tablename__ = "zomato_item_groups"

    id = Column(BigInteger, primary_key=True)
    zomato_item_id = Column(BigInteger)
    name = Column(String)
    min_selection = Column(Integer)
    max_selection = Column(Integer)
    group_types = Column(String)


class ZomatoItemGroupChoice(Base):
    __tablename__ = "zomato_item_group_choices"

    id = Column(BigInteger, primary_key=True)
    zomato_item_group_id = Column(Integer)
    name = Column(String)
    description = Column(Text)
    price = Column(Integer)
    pricing_mode = Column(String)
