import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/widgets/brand_logo.dart';

/// Les logos rendus dans la variante [v] (decidee a la mise en page).
Finder logoRendu(VarianteLogo v) => find.byElementPredicate(
  (Element e) =>
      e.widget is LogoPeint &&
      (e.renderObject! as RenduLogo).varianteRendue == v,
);
