import 'package:flutter/cupertino.dart';

import '../data/contact_store.dart';
import 'theme.dart';
import 'widgets.dart';
import '../l10n/strings.dart';

/// Окно со списком интересов: создать заранее, посмотреть, у скольких
/// людей указан, удалить.
Future<void> showInterestsPanel(BuildContext context, {required ContactStore store}) =>
    showModal<void>(context, builder: (_) => _InterestsPanel(store: store));

class _InterestsPanel extends StatefulWidget {
  final ContactStore store;
  const _InterestsPanel({required this.store});

  @override
  State<_InterestsPanel> createState() => _InterestsPanelState();
}

class _InterestsPanelState extends State<_InterestsPanel> {
  final _input = TextEditingController();
  final _focus = FocusNode();
  String? _error;

  ContactStore get store => widget.store;

  @override
  void dispose() {
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final names = _input.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    if (names.isEmpty) return;
    var added = 0;
    for (final n in names) {
      if (await store.addInterest(n)) added++;
    }
    setState(() => _error = added == 0 ? tr.interestExists : null);
    if (added > 0) _input.clear();
    _focus.requestFocus();
  }

  Future<void> _delete(String interest) async {
    final n = store.interestUsage(interest);
    final ok = await confirmDialog(
      context,
      title: tr.deleteInterestTitle(interest),
      message: n == 0
          ? tr.deleteInterestUnused
          : tr.deleteInterestMessage(n),
      confirmLabel: tr.delete,
      destructive: true,
    );
    if (ok) await store.deleteInterest(interest);
  }

  @override
  Widget build(BuildContext context) {
    void close() => Navigator.of(context).pop();
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final interests = store.interestCatalog;
        return ModalScaffold(
          title: tr.interests,
          subtitle: tr.interestsSubtitle,
          width: 520,
          onCancel: close,
          actions: [Btn.primary(label: tr.done, onPressed: close)],
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Labeled(
                    label: tr.newInterestLabel,
                    error: _error,
                    child: Field(
                      controller: _input,
                      focusNode: _focus,
                      autofocus: true,
                      placeholder: tr.interestsPlaceholder,
                      icon: CupertinoIcons.sparkles,
                      error: _error != null,
                      onChanged: (_) {
                        if (_error != null) setState(() => _error = null);
                      },
                      onSubmitted: (_) => _add(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Btn.primary(label: tr.add, icon: CupertinoIcons.plus, onPressed: _add),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (interests.isEmpty)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: Pal.border)),
                child: Text(tr.noInterests, textAlign: TextAlign.center, style: T.body.copyWith(color: Pal.muted)),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: Pal.raised,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Pal.border),
                ),
                child: Column(
                  children: [
                    for (final (i, e) in interests.indexed)
                      Container(
                        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                        decoration: BoxDecoration(
                          border: i == 0 ? null : Border(top: BorderSide(color: Pal.border)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(color: TagColors.hue(e.key), shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Text(e.key, style: T.body)),
                            Text(
                              e.value == 0 ? tr.nobody : tr.contacts(e.value),
                              style: T.small,
                            ),
                            const SizedBox(width: 8),
                            IconBtn(
                              icon: CupertinoIcons.trash,
                              hint: tr.deleteInterest,
                              size: 32,
                              onPressed: () => _delete(e.key),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
