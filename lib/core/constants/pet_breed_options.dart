class PetBreedOptions {
  static const other = 'Otro';

  static const dogBreeds = [
    'Mestizo',
    'Golden Retriever',
    'Labrador',
    'Labrador Retriever',
    'Pastor Aleman',
    'Caniche / Poodle',
    'Bulldog',
    'Bulldog Frances',
    'Beagle',
    'Boxer',
    'Rottweiler',
    'Husky Siberiano',
    'Border Collie',
    'Dachshund / Salchicha',
    'Chihuahua',
    'Yorkshire Terrier',
    'Shih Tzu',
    'Schnauzer',
    'Cocker Spaniel',
    'Pitbull',
    'Doberman',
    'Akita',
    'Galgo',
    'Bichon Frise',
    'Dalmata',
  ];

  static const catBreeds = [
    'Mestizo',
    'Comun Europeo',
    'Persa',
    'Siames',
    'Maine Coon',
    'Bengali',
    'Ragdoll',
    'Britanico de pelo corto',
    'Azul Ruso',
    'Sphynx',
    'Angora',
    'Bosque de Noruega',
    'Scottish Fold',
    'Abisinio',
    'Birmano',
  ];

  static List<String> forType(String type, {bool includeOther = false}) {
    final breeds = switch (type) {
      'dog' => dogBreeds,
      'cat' => catBreeds,
      _ => [...dogBreeds, ...catBreeds],
    };
    final unique = breeds.toSet().toList()..sort();
    return includeOther ? [...unique, other] : unique;
  }
}
