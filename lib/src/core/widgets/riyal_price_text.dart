import 'package:flutter/widgets.dart';

/// Dont forget to add the font to pubspec
///
/// - family: Riyal
///   fonts:
///     - asset: assets/fonts/riyal.ttf
///

const IconData saudiRiyalSymbolIconData = IconData(0xe800, fontFamily: 'Riyal');

class RiyalPriceText extends StatelessWidget {
  final String price;
  final TextStyle? priceTextStyle;
  final TextStyle? currencyTextStyle;

  const RiyalPriceText({
    super.key,
    required this.price,
    this.priceTextStyle,
    this.currencyTextStyle,
  });

  bool checkIfPriceOnly() {
    final regx = RegExp(r'(\d+\.\d+)');
    return regx.hasMatch(price);
  }

  String getPrice() {
    if (checkIfPriceOnly()) {
      return price;
    } else {
      return price.split(' ').firstOrNull ?? "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return RichText(
      textHeightBehavior: const TextHeightBehavior(
        applyHeightToFirstAscent: false,
        applyHeightToLastDescent: false,
      ),
      text: TextSpan(
        children: [
          TextSpan(text: "${getPrice()} ", style: priceTextStyle),
          WidgetSpan(
            child: Text(
              String.fromCharCode(saudiRiyalSymbolIconData.codePoint),
              style:
                  (currencyTextStyle?.copyWith(
                            fontFamily: saudiRiyalSymbolIconData.fontFamily,
                          ) ??
                          priceTextStyle?.copyWith(
                            fontFamily: saudiRiyalSymbolIconData.fontFamily,
                          ) ??
                          TextStyle(
                            fontFamily: saudiRiyalSymbolIconData.fontFamily,
                          ))
                      .copyWith(height: 1),
            ),
          ),
        ],
      ),
    );
  }
}

extension RiyalPrice on Text {
  Widget withRiyalPrice({
    Color? color,
    Color? priceColor,
    Color? currencyColor,
  }) {
    final finalPriceColor = priceColor ?? color;
    final finalCurrencyColor = currencyColor ?? color;

    return RiyalPriceText(
      price: data.toString(),
      priceTextStyle: finalPriceColor != null
          ? style?.copyWith(color: finalPriceColor) ??
                TextStyle(color: finalPriceColor)
          : style,
      currencyTextStyle: finalCurrencyColor != null
          ? style?.copyWith(color: finalCurrencyColor) ??
                TextStyle(color: finalCurrencyColor)
          : style,
    );
  }
}
