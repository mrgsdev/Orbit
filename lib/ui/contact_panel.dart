import 'package:flutter/material.dart';

import '../data/contact_store.dart';
import '../models/contact.dart';
import 'contact_detail.dart';
import 'contact_form.dart';
import 'theme.dart';
import 'widgets.dart';

/// Выезжающая справа панель: просмотр контакта или его редактирование.
/// Без [contact] открывается сразу форма нового контакта.
Future<void> showContactPanel(
  BuildContext context, {
  required ContactStore store,
  Contact? contact,
}) =>
    showSidePanel(context, child: _ContactPanel(store: store, contact: contact));

/// Оболочка панели, выезжающей справа поверх затемнения.
Future<void> showSidePanel(
  BuildContext context, {
  required Widget child,
  double width = 500,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Закрыть',
    barrierColor: Colors.black.withValues(alpha: 0.22),
    transitionDuration: const Duration(milliseconds: 240),
    pageBuilder: (context, _, _) => Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          width: width,
          child: Container(
            decoration: cardDecoration(context.colors, radius: 18).copyWith(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 40,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            // Свой мессенджер, чтобы тосты показывались поверх панели,
            // а не под затемнением.
            child: ScaffoldMessenger(
              child: Scaffold(backgroundColor: Colors.transparent, body: child),
            ),
          ),
        ),
      ),
    ),
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return SlideTransition(
        position: Tween(begin: const Offset(0.6, 0), end: Offset.zero).animate(curved),
        child: FadeTransition(opacity: curved, child: child),
      );
    },
  );
}

class _ContactPanel extends StatefulWidget {
  final ContactStore store;
  final Contact? contact;

  const _ContactPanel({required this.store, this.contact});

  @override
  State<_ContactPanel> createState() => _ContactPanelState();
}

class _ContactPanelState extends State<_ContactPanel> {
  late Contact _contact = widget.contact ?? widget.store.newDraft();
  late bool _editing = widget.contact == null;
  bool _closing = false;

  ContactStore get store => widget.store;
  bool get _isNew => store.byId(_contact.id) == null;

  /// Закрывает панель в обход защиты от потери правок.
  void _close() {
    setState(() => _closing = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  Future<void> _delete() async {
    final ok = await confirmDialog(
      context,
      title: 'Удалить «${_contact.name}»?',
      message: 'Контакт и его фото будут удалены без возможности восстановления.',
      confirmLabel: 'Удалить',
      destructive: true,
    );
    if (!ok) return;
    await store.delete(_contact);
    _close();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_editing || _closing,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final ok = await confirmDialog(
          context,
          title: 'Закрыть без сохранения?',
          message: 'Несохранённые изменения будут потеряны.',
          confirmLabel: 'Закрыть',
          destructive: true,
        );
        if (ok) _close();
      },
      child: _editing
          ? ContactForm(
              key: ValueKey('form-${_contact.id}'),
              initial: _contact,
              store: store,
              isNew: _isNew,
              onSaved: (c) => setState(() {
                _contact = c;
                _editing = false;
              }),
              onCancel: () => _isNew ? _close() : setState(() => _editing = false),
            )
          : ListenableBuilder(
              listenable: store,
              builder: (context, _) {
                final current = store.byId(_contact.id);
                if (current == null) return const SizedBox.shrink();
                return ContactDetail(
                  contact: current,
                  store: store,
                  onEdit: () => setState(() {
                    _contact = current;
                    _editing = true;
                  }),
                  onDelete: _delete,
                  onClose: () => Navigator.of(context).maybePop(),
                );
              },
            ),
    );
  }
}
