import pandas as pd

df = pd.read_csv('/Users/vamsydamekar/Downloads/Project 1/Smartphones_cleaned_dataset.csv')

# Clean brand name column
df['brand_name'] = df['brand_name'].astype(str).str.strip().str.title()

# Clean price column (remove ₹ and commas), convert to float
df['price'] = df['price'].replace('[\₹,]', '', regex=True).astype(float)

# Extract digits from ram_capacity after converting to string
df['ram_capacity'] = df['ram_capacity'].astype(str).str.extract(r'(\d+)').astype(float)


# Define price segments
def price_segment(price):
    if price < 10000:
        return 'Budget'
    elif price < 25000:
        return 'Midrange'
    else:
        return 'Premium'

df['price_segment'] = df['price'].apply(price_segment)

# Extract rating number after converting to string (sometimes rating may be NaN or other format)
df['rating'] = df['rating'].astype(str).str.extract(r'(\d+\.\d+)').astype(float)

# Drop rows with missing price or rating
df = df.dropna(subset=['price', 'rating'])

# Fill any remaining missing rating with median (optional, if any left)
df['rating'] = df['rating'].fillna(df['rating'].median())

# Calculate value_score
df['value_score'] = df['rating'] / df['price']

# Convert brand_name column to dummies (fix the column name to 'brand_name')
df = pd.get_dummies(df, columns=['brand_name'], prefix='brand')


print(df)
print(df.head())
