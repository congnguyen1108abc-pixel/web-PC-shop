// Shared Brand Mapping Logic for Admin and Gaming Gear
const CATEGORY_BRAND_MAPPING = {
    'cpu': ['intel', 'amd'],
    'mainboard': ['asus', 'msi', 'gigabyte', 'asrock', 'colorful', 'biostar'],
    'ram': ['kingston', 'adata', 'corsair', 'g.skill', 'teamgroup', 'crucial', 'lexar'],
    'ssd': ['samsung', 'kingston', 'wd', 'crucial', 'adata', 'corsair', 'teamgroup', 'lexar', 'seagate'],
    'vga': ['asus', 'msi', 'gigabyte', 'colorful', 'palit', 'zotac'],
    'psu': ['corsair', 'asus', 'gigabyte', 'msi', 'deepcool', 'thermaltake', 'antec'],
    'case': ['corsair', 'deepcool', 'thermaltake', 'antec', 'coolmoon', 'nzxt', 'asus', 'msi', 'gigabyte'],
    'vỏ máy tính': ['corsair', 'deepcool', 'thermaltake', 'antec', 'coolmoon', 'nzxt', 'asus', 'msi', 'gigabyte'],
    'tản nhiệt': ['corsair', 'deepcool', 'thermaltake', 'nzxt', 'cooler master', 'asus', 'msi', 'gigabyte'],
    'gaming gear': ['logitech', 'razer', 'steelseries', 'hyperx', 'akko', 'aula', 'attack shark', 'dareu', 'rapoo', 'keychron', 'hyper core', 'corsair', 'asus', 'msi', 'edifier', 'lamzu', 'pulsar', 'glorious', 'xtrfy'],
    'laptop': ['asus', 'acer', 'dell', 'hp', 'lenovo', 'msi', 'lg', 'huawei', 'apple', 'gigabyte', 'microsoft'],
    'pc': ['asus', 'acer', 'dell', 'hp', 'lenovo', 'msi', 'apple', 'gigabyte', 'intel']
};

window.getSharedBrandMapping = function() {
    return CATEGORY_BRAND_MAPPING;
};

window.getFilteredBrandsForCategory = function(allBrands, categoryName) {
    if (!categoryName) return [];
    
    const catNameLower = categoryName.toLowerCase();
    let matchedMapping = null;
    
    for (const [key, brands] of Object.entries(CATEGORY_BRAND_MAPPING)) {
        if (catNameLower.includes(key)) {
            matchedMapping = brands;
            break;
        }
    }
    
    if (!matchedMapping) return allBrands;
    
    return allBrands.filter(b => {
        const bLower = (b.brandName || '').toLowerCase();
        return matchedMapping.some(allowed => bLower === allowed || bLower.includes(allowed));
    });
};
