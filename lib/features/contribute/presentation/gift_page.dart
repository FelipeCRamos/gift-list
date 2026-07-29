import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/formatting/brl_money.dart';
import '../../../core/routing/route_paths.dart';
import '../../../core/widgets/widgets.dart';
import '../../../services/payments/payment_instruction.dart';
import 'gift_cubit.dart';

/// `/l/:slug/gift/:itemId` — the contribute flow: a form to describe the gift,
/// then the Pix payment view (QR + copia-e-cola + "I've paid").
class GiftPage extends StatelessWidget {
  const GiftPage({required this.slug, required this.itemId, super.key});

  final String slug;
  final String itemId;

  @override
  Widget build(BuildContext context) {
    return GlPageScaffold(
      title: 'Contribute',
      body: BlocBuilder<GiftCubit, GiftState>(
        builder: (context, state) {
          switch (state.status) {
            case GiftStatus.initial:
            case GiftStatus.loading:
              return const GlAsyncView(loading: true, builder: _empty);
            case GiftStatus.failure:
              return GlAsyncView(
                loading: false,
                error: state.errorMessage ?? 'Something went wrong',
                onRetry: () => context.read<GiftCubit>().load(),
                builder: _empty,
              );
            case GiftStatus.denied:
              return _DeniedView(slug: slug, itemId: itemId);
            case GiftStatus.unavailable:
              return _UnavailableView(slug: slug);
            case GiftStatus.ready:
            case GiftStatus.submitting:
              return _GiftForm(state: state);
            case GiftStatus.awaitingPayment:
              return _PaymentView(slug: slug, state: state);
          }
        },
      ),
    );
  }
}

Widget _empty(BuildContext context) => const SizedBox.shrink();

class _GiftForm extends StatefulWidget {
  const _GiftForm({required this.state});

  final GiftState state;

  @override
  State<_GiftForm> createState() => _GiftFormState();
}

class _GiftFormState extends State<_GiftForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _message;
  late final TextEditingController _amount;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.state.giverName);
    _message = TextEditingController();
    _amount = TextEditingController();
  }

  @override
  void dispose() {
    _name.dispose();
    _message.dispose();
    _amount.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final GiftState state = widget.state;
    final int amountCents = state.isPartial
        ? (tryParseReaisToCents(_amount.text) ?? 0)
        : (state.item?.targetAmountCents ?? 0);
    context.read<GiftCubit>().submit(
      giverName: _name.text,
      amountCents: amountCents,
      giverMessage: _message.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final GiftState state = widget.state;
    final String itemTitle = state.item?.title ?? '';
    return GlFormLayout(
      formKey: _formKey,
      children: [
        Text(itemTitle, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(
          state.isPartial
              ? 'Remaining: ${centsToBrl(state.remainingCents)}'
              : 'Full gift: ${centsToBrl(state.item?.targetAmountCents ?? 0)}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _name,
          decoration: const InputDecoration(labelText: 'Your name'),
          textInputAction: TextInputAction.next,
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Please enter your name' : null,
        ),
        const SizedBox(height: 16),
        if (state.isPartial)
          TextFormField(
            controller: _amount,
            decoration: const InputDecoration(
              labelText: r'Amount (R$)',
              hintText: '0,00',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (v) {
              final int? cents = tryParseReaisToCents(v ?? '');
              if (cents == null || cents < 1) {
                return 'Enter a valid amount';
              }
              if (cents > state.remainingCents) {
                return 'Max ${centsToBrl(state.remainingCents)}';
              }
              return null;
            },
          ),
        if (state.isPartial) const SizedBox(height: 16),
        TextFormField(
          controller: _message,
          decoration: const InputDecoration(labelText: 'Message (optional)'),
          maxLines: 2,
        ),
        if (state.errorMessage != null) ...[
          const SizedBox(height: 16),
          Text(
            state.errorMessage!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 24),
        GlBusyButton(
          label: 'Generate Pix',
          busy: state.status == GiftStatus.submitting,
          onPressed: _submit,
        ),
      ],
    );
  }
}

class _PaymentView extends StatelessWidget {
  const _PaymentView({required this.slug, required this.state});

  final String slug;
  final GiftState state;

  @override
  Widget build(BuildContext context) {
    final String code = switch (state.instruction) {
      final PixInstruction i => i.copiaECola,
      null => '',
    };
    final int amount = state.contribution?.amountCents ?? 0;
    return GlFormLayout(
      children: [
        Text(
          'Pay ${centsToBrl(amount)} via Pix',
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Scan the QR in your bank app, or copy the code below.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        Center(
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: QrImageView(data: code, size: 220),
          ),
        ),
        const SizedBox(height: 24),
        SelectableText(
          code,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: code));
            if (context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Pix code copied')));
            }
          },
          icon: const Icon(Icons.copy),
          label: const Text('Copy Pix code'),
        ),
        const SizedBox(height: 24),
        GlBusyButton(
          label: "I've paid",
          onPressed: () => context.go(RoutePaths.toThanks(slug)),
        ),
        const SizedBox(height: 8),
        Text(
          'The creator will confirm once the transfer lands.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _DeniedView extends StatelessWidget {
  const _DeniedView({required this.slug, required this.itemId});

  final String slug;
  final String itemId;

  @override
  Widget build(BuildContext context) {
    return GlEmptyState(
      icon: Icons.lock_outline,
      title: 'Sign in to contribute',
      message: 'This list requires signing in before you can gift.',
      action: FilledButton(
        onPressed: () =>
            context.go(RoutePaths.authFrom(RoutePaths.toGift(slug, itemId))),
        child: const Text('Sign in'),
      ),
    );
  }
}

class _UnavailableView extends StatelessWidget {
  const _UnavailableView({required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context) {
    return GlEmptyState(
      icon: Icons.check_circle_outline,
      title: 'Already taken',
      message: 'This item has been fully gifted or is reserved right now.',
      action: OutlinedButton(
        onPressed: () => context.go(RoutePaths.toListView(slug)),
        child: const Text('Back to the list'),
      ),
    );
  }
}
