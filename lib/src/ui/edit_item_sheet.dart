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
  String? validationError;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          return GlassBackground(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: GlassPanel(
                padding: const EdgeInsets.all(18),
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
                        labelText: '分类',
                        prefixIcon: const Icon(Icons.folder_outlined),
                        errorText: validationError,
                      ),
                      textInputAction: TextInputAction.next,
                    ),
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
                              validationError = '分类不能为空';
                            });
                            return;
                          }
                          _appendKeyword(keywords, keywordInputController.text);
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
          );
        },
      );
    },
  );
  categoryController.dispose();
  keywordInputController.dispose();
  notesController.dispose();
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
