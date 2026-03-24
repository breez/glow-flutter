import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/providers/sdk_provider.dart';
import 'package:glow/features/receive/widgets/copy_and_share_actions.dart';
import 'package:glow/features/receive/widgets/error_view.dart';
import 'package:glow/features/receive/widgets/lightning_address_card.dart';
import 'package:glow/features/receive/widgets/no_lightning_address_view.dart';
import 'package:glow/widgets/qr_code_card.dart';
import 'package:glow/features/receive/widgets/edit_lightning_address_sheet.dart';
import 'package:glow/features/receive/widgets/register_lightning_address_sheet.dart';
import 'package:glow/widgets/card_wrapper.dart';

/// Lightning receive view - displays Lightning Address with QR code
class LightningReceiveView extends ConsumerWidget {
  const LightningReceiveView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<LightningAddressInfo?> lightningAddress = ref.watch(
      lightningAddressProvider(true),
    );
    final AsyncValue<BreezSdk> sdkAsync = ref.watch(sdkProvider);

    return lightningAddress.when(
      data: (LightningAddressInfo? address) => address != null
          ? _LightningAddressContent(
              address: address.lightningAddress,
              lnurl: address.lnurl,
              sdk: sdkAsync.value!,
            )
          : NoLightningAddressView(
              onRegister: () async {
                final BreezSdk? sdk = sdkAsync.value;
                if (sdk != null) {
                  await showRegisterLightningAddressSheet(context, ref, sdk);
                }
              },
            ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object err, _) =>
          ErrorView(message: 'Failed to load Lightning Address', error: err.toString()),
    );
  }
}

/// Content displayed when Lightning Address exists
class _LightningAddressContent extends ConsumerWidget {
  final BreezSdk sdk;
  final String address;
  final LnurlInfo lnurl;

  const _LightningAddressContent({required this.sdk, required this.address, required this.lnurl});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: CardWrapper(
        child: Column(
          children: <Widget>[
            QRCodeCard(data: lnurl.bech32),
            const SizedBox(height: 24),
            CopyAndShareActions(copyData: address, shareData: lnurl.bech32),
            const SizedBox(height: 24),
            LightningAddressCard(
              address: address,
              onEdit: () => showEditLightningAddressSheet(context, ref, sdk, address),
            ),
          ],
        ),
      ),
    );
  }
}
