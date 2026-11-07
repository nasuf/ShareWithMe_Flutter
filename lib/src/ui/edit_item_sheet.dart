part of '../../main.dart';

Future<void> showEditItemSheet(
  BuildContext context,
  ShareController controller,
  LinkItem item,
) async {
  final categoryController = TextEditingController(text: item.category);
  final keywordInputController = TextEditingController();
  final notesController = TextEditingController(text: item.notes);
  final keywords = [...item.keywords];
  final existingFolders = _existingFolders(controller, item.category);
  String? validationError;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: _ink.withValues(alpha: 0.16),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          return ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
              child: ColoredBox(
                color: Colors.white.withValues(alpha: 0.8),
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '编辑整理信息',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w900),
                              ),
                            ),
                            IconButton(
                              tooltip: '关闭',
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: categoryController,
                          decoration: InputDecoration(
                            labelText: '收藏夹',
                            prefixIcon: const Icon(Icons.folder_outlined),
                            errorText: validationError,
                            helperText: existingFolders.isEmpty
                                ? null
                                : '点选已有收藏夹，或输入新名称',
                          ),
                          textInputAction: TextInputAction.next,
                          onChanged: (_) {
                            if (validationError != null) {
                              setSheetState(() => validationError = null);
                            }
                          },
                        ),
                        if (existingFolders.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          ValueListenableBuilder<TextEditingValue>(
                            valueListenable: categoryController,
                            builder: (context, value, _) {
                              final current = value.text.trim();
                              return Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final folder in existingFolders)
                                    ChoiceChip(
                                      selected: current == folder,
                                      showCheckmark: false,
                                      avatar: const Icon(
                                        Icons.folder_outlined,
                                        size: 16,
                                      ),
                                      label: Text(folder),
                                      onSelected: (_) {
                                        categoryController.text = folder;
                                        if (validationError != null) {
                                          setSheetState(
                                            () => validationError = null,
                                          );
                                        }
                                      },
                                    ),
                                ],
                              );
                            },
                          ),
                        ],
                        const SizedBox(height: 14),
                        _KeywordEditorField(
                          keywords: keywords,
                          inputController: keywordInputController,
                          onChanged: () => setSheetState(() {}),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: notesController,
                          minLines: 3,
                          maxLines: 6,
                          decoration: const InputDecoration(
                            labelText: '备注',
                            prefixIcon: Icon(Icons.notes_outlined),
                            alignLabelWithHint: true,
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () async {
                              final category = categoryController.text.trim();
                              if (category.isEmpty) {
                                setSheetState(() {
                                  validationError = '收藏夹名称不能为空';
                                });
                                return;
                              }
                              _appendKeyword(
                                keywords,
                                keywordInputController.text,
                              );
                              await controller.editItem(
                                item: item,
                                category: category,
                                keywords: keywords,
                                notes: notesController.text,
                              );
                              if (context.mounted) {
                                Navigator.of(context).pop();
                              }
                            },
                            icon: const Icon(Icons.save_outlined),
                            label: const Text('保存'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
  categoryController.dispose();
  keywordInputController.dispose();
  notesController.dispose();
}

// Folders already in use, most used first, so editing reuses one instead of
// spawning a near-duplicate through a typo. The item's own folder is included
// even when the current stats snapshot does not cover it.
List<String> _existingFolders(ShareController controller, String current) {
  final folders = <String>{};
  for (final bucket in controller.stats?.categories ?? const <CountBucket>[]) {
    final label = bucket.label.trim();
    if (label.isNotEmpty) {
      folders.add(label);
    }
  }
  final trimmed = current.trim();
  if (trimmed.isNotEmpty) {
    folders.add(trimmed);
  }
  return folders.toList(growable: false);
}

class _KeywordEditorField extends StatelessWidget {
  const _KeywordEditorField({
    required this.keywords,
    required this.inputController,
    required this.onChanged,
  });

  final List<String> keywords;
  final TextEditingController inputController;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '关键词',
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final keyword in keywords)
              SoftTag(
                label: keyword,
                icon: Icons.sell_outlined,
                onDeleted: () {
                  keywords.remove(keyword);
                  onChanged();
                },
              ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: inputController,
                decoration: const InputDecoration(
                  hintText: '输入新关键词',
                  prefixIcon: Icon(Icons.add),
                ),
                onSubmitted: (_) {
                  _appendKeyword(keywords, inputController.text);
                  inputController.clear();
                  onChanged();
                },
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () {
                _appendKeyword(keywords, inputController.text);
                inputController.clear();
                onChanged();
              },
              child: const Text('添加'),
            ),
          ],
        ),
      ],
    );
  }
}

void _appendKeyword(List<String> keywords, String input) {
  for (final keyword in parseKeywords(input)) {
    if (!keywords.contains(keyword) && keywords.length < 20) {
      keywords.add(keyword);
    }
  }
}

List<String> parseKeywords(String input) {
  final chunks = input
      .split(RegExp(r'[\s,，、;；]+'))
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toList();
  final keywords = <String>[];
  for (final chunk in chunks) {
    if (!keywords.contains(chunk)) {
      keywords.add(chunk);
    }
    if (keywords.length >= 20) {
      break;
    }
  }
  return keywords;
}
