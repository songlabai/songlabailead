// Enhanced Business Targeting Configuration for SongLabAI Lead Generation
// Expanded from original 7 types to 45+ types for better market coverage

const businessTypes = {
  // HIGH-PRIORITY TARGETS (Premium Pricing: $399-$499)
  // These businesses have higher budgets and see immediate ROI from jingles
  primary: {
    automotive: {
      types: ['car_dealer', 'car_rental', 'car_repair', 'motorcycle_dealer', 'rv_dealer', 'boat_dealer'],
      priority: 35,
      avgBudget: 499,
      searchTerms: ['car dealer', 'auto dealer', 'car rental', 'auto repair', 'motorcycle dealer'],
      emailTemplate: 'automotive',
      calendlyUrl: 'automotive'
    },
    
    restaurants: {
      types: ['restaurant', 'meal_takeaway', 'meal_delivery', 'bar', 'cafe', 'bakery', 'food', 'night_club'],
      priority: 30,
      avgBudget: 399,
      searchTerms: ['restaurant', 'cafe', 'bar', 'bakery', 'fast food', 'fine dining'],
      emailTemplate: 'restaurant',
      calendlyUrl: 'restaurant'
    },
    
    legal: {
      types: ['lawyer', 'legal_services'],
      priority: 28,
      avgBudget: 499,
      searchTerms: ['law firm', 'attorney', 'lawyer', 'legal services', 'law office'],
      emailTemplate: 'legal',
      calendlyUrl: 'general'
    },
    
    medical: {
      types: ['doctor', 'dentist', 'hospital', 'pharmacy', 'physiotherapist', 'veterinary_care'],
      priority: 25,
      avgBudget: 399,
      searchTerms: ['doctor', 'dentist', 'medical clinic', 'pharmacy', 'veterinarian', 'physical therapy'],
      emailTemplate: 'medical',
      calendlyUrl: 'general'
    },
    
    realEstate: {
      types: ['real_estate_agency', 'moving_company', 'storage'],
      priority: 25,
      avgBudget: 399,
      searchTerms: ['real estate', 'realtor', 'property management', 'moving company'],
      emailTemplate: 'real-estate',
      calendlyUrl: 'general'
    }
  },
  
  // MEDIUM-PRIORITY TARGETS (Good Volume: $199-$299)
  // Steady volume, good conversion rates
  secondary: {
    fitness: {
      types: ['gym', 'spa', 'beauty_salon', 'hair_care', 'nail_salon'],
      priority: 22,
      avgBudget: 299,
      searchTerms: ['gym', 'fitness center', 'yoga studio', 'spa', 'beauty salon', 'hair salon'],
      emailTemplate: 'fitness',
      calendlyUrl: 'general'
    },
    
    retail: {
      types: ['clothing_store', 'jewelry_store', 'shoe_store', 'electronics_store', 'furniture_store', 'florist'],
      priority: 20,
      avgBudget: 249,
      searchTerms: ['clothing store', 'boutique', 'jewelry store', 'electronics store', 'furniture store'],
      emailTemplate: 'retail',
      calendlyUrl: 'general'
    },
    
    professional: {
      types: ['accounting', 'insurance_agency', 'travel_agency', 'bank', 'credit_union'],
      priority: 22,
      avgBudget: 349,
      searchTerms: ['accountant', 'insurance agency', 'travel agency', 'financial advisor', 'tax service'],
      emailTemplate: 'professional-services',
      calendlyUrl: 'general'
    },
    
    homeServices: {
      types: ['general_contractor', 'electrician', 'plumber', 'locksmith', 'pest_control', 'roofing_contractor'],
      priority: 18,
      avgBudget: 249,
      searchTerms: ['contractor', 'electrician', 'plumber', 'hvac', 'roofing', 'landscaping'],
      emailTemplate: 'professional-services',
      calendlyUrl: 'general'
    }
  },
  
  // EMERGING TARGETS (Growth Opportunity: $199-$399)
  // Newer markets with good potential
  emerging: {
    entertainment: {
      types: ['event_venue', 'wedding_venue', 'banquet_hall', 'bowling_alley', 'amusement_park'],
      priority: 20,
      avgBudget: 299,
      searchTerms: ['wedding venue', 'event venue', 'banquet hall', 'party venue', 'entertainment center'],
      emailTemplate: 'professional-services',
      calendlyUrl: 'general'
    },
    
    education: {
      types: ['school', 'university', 'driving_school', 'dance_school', 'music_school'],
      priority: 18,
      avgBudget: 299,
      searchTerms: ['private school', 'tutoring center', 'driving school', 'music school', 'dance studio'],
      emailTemplate: 'professional-services',
      calendlyUrl: 'general'
    },
    
    petServices: {
      types: ['pet_store', 'veterinary_care', 'pet_grooming'],
      priority: 16,
      avgBudget: 249,
      searchTerms: ['pet store', 'veterinarian', 'pet grooming', 'dog training', 'pet boarding'],
      emailTemplate: 'professional-services',
      calendlyUrl: 'general'
    },
    
    techServices: {
      types: ['computer_store', 'electronics_repair', 'phone_repair'],
      priority: 15,
      avgBudget: 199,
      searchTerms: ['computer repair', 'phone repair', 'electronics store', 'IT services'],
      emailTemplate: 'professional-services',
      calendlyUrl: 'general'
    }
  }
};

// Premium California locations with scoring bonuses
const premiumLocations = {
  ultraPremium: {
    bonus: 25,
    cities: [
      'Beverly Hills, CA',
      'Malibu, CA',
      'Santa Monica, CA',
      'Palo Alto, CA',
      'Carmel-by-the-Sea, CA',
      'Sausalito, CA'
    ]
  },
  
  premium: {
    bonus: 20,
    cities: [
      'Manhattan Beach, CA',
      'Hermosa Beach, CA',
      'Redondo Beach, CA',
      'Laguna Beach, CA',
      'Mill Valley, CA',
      'Half Moon Bay, CA',
      'Tiburon, CA'
    ]
  },
  
  highValue: {
    bonus: 15,
    cities: [
      'Los Angeles, CA',
      'San Francisco, CA',
      'San Diego, CA',
      'San Jose, CA',
      'Newport Beach, CA',
      'Santa Barbara, CA',
      'Monterey, CA',
      'Napa, CA',
      'Sonoma, CA'
    ]
  },
  
  standard: {
    bonus: 10,
    cities: [
      'Oakland, CA',
      'Long Beach, CA',
      'Fresno, CA',
      'Sacramento, CA',
      'Anaheim, CA',
      'Irvine, CA',
      'Pasadena, CA',
      'Berkeley, CA'
    ]
  }
};

// Search configuration for different days/times
const searchStrategy = {
  dailyRotation: {
    monday: ['automotive', 'realEstate'],
    tuesday: ['restaurants', 'retail'],
    wednesday: ['legal', 'medical'],
    thursday: ['professional', 'homeServices'],
    friday: ['fitness', 'entertainment'],
    saturday: ['education', 'petServices'],
    sunday: ['techServices', 'emerging']
  },
  
  timeSlots: {
    morning: {
      time: '09:00',
      focus: 'primary',
      areas: 'ultraPremium,premium'
    },
    afternoon: {
      time: '14:00',
      focus: 'secondary',
      areas: 'premium,highValue'
    },
    evening: {
      time: '18:00',
      focus: 'emerging',
      areas: 'standard'
    }
  }
};

// Lead scoring algorithm
const leadScoring = {
  baseScores: {
    businessType: {
      automotive: 35,
      restaurants: 30,
      legal: 28,
      medical: 25,
      realEstate: 25,
      fitness: 22,
      professional: 22,
      retail: 20,
      homeServices: 18,
      entertainment: 20,
      education: 18,
      petServices: 16,
      techServices: 15
    }
  },
  
  bonusFactors: {
    premiumLocation: {
      ultraPremium: 25,
      premium: 20,
      highValue: 15,
      standard: 10
    },
    
    businessQuality: {
      rating45Plus: 15,
      rating40Plus: 10,
      rating35Plus: 5,
      reviews100Plus: 15,
      reviews50Plus: 10,
      reviews20Plus: 5,
      hasWebsite: 10,
      hasPhone: 5,
      priceLevel3Plus: 15,
      priceLevel2Plus: 10
    }
  },
  
  minimumScore: 45,  // Only prospects with 45+ points are contacted
  premiumScore: 70   // High-priority prospects for immediate follow-up
};

// Email personalization data
const personalizationData = {
  automotive: {
    painPoints: ['standing out from competition', 'brand recall', 'professional image'],
    benefits: ['increased foot traffic', 'memorable brand identity', 'premium positioning'],
    examples: ['luxury car dealerships', 'automotive service centers']
  },
  
  restaurants: {
    painPoints: ['customer retention', 'brand recognition', 'atmosphere creation'],
    benefits: ['repeat customers', 'word-of-mouth marketing', 'memorable dining experience'],
    examples: ['fine dining establishments', 'popular local eateries']
  },
  
  legal: {
    painPoints: ['building trust', 'professional credibility', 'client confidence'],
    benefits: ['enhanced reputation', 'client trust', 'professional distinction'],
    examples: ['established law firms', 'legal practices']
  }
  // ... more personalization data for each type
};

module.exports = {
  businessTypes,
  premiumLocations,
  searchStrategy,
  leadScoring,
  personalizationData
};