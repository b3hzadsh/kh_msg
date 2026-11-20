import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'models/course_message_models.dart';
import 'providers/message_builder_provider.dart';

void main() {
  runApp(const CourseMessageBuilderApp());
}

class CourseMessageBuilderApp extends StatelessWidget {
  const CourseMessageBuilderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<MessageBuilderProvider>(
      create: (_) => MessageBuilderProvider()..loadInitialData(),
      child: MaterialApp(
        title: 'سازنده پیام دوره‌ها',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
        home: const Directionality(
          textDirection: TextDirection.rtl,
          child: MessageBuilderHomePage(),
        ),
      ),
    );
  }
}

class MessageBuilderHomePage extends StatefulWidget {
  const MessageBuilderHomePage({super.key});

  @override
  State<MessageBuilderHomePage> createState() => _MessageBuilderHomePageState();
}

class _MessageBuilderHomePageState extends State<MessageBuilderHomePage> {
  Future<void> _openProfileDialog(
    BuildContext context,
    MessageBuilderProvider provider,
  ) async {
    final senderController = TextEditingController(text: provider.senderTitle);
    final orgController = TextEditingController(text: provider.orgTitle);
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('تنظیم مشخصات ثابت'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: senderController,
                    decoration: const InputDecoration(
                      labelText: 'عنوان یا نام ثابت',
                      hintText: 'مثلاً: مهندس X',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'لطفاً عنوان یا نام ثابت را وارد کنید';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: orgController,
                    decoration: const InputDecoration(
                      labelText: 'نام یا عنوان مجموعه',
                      hintText: 'مثلاً: کارشناس مجموعه Y',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'لطفاً نام مجموعه را وارد کنید';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('انصراف'),
              ),
              FilledButton(
                onPressed: () {
                  if (formKey.currentState?.validate() ?? false) {
                    Navigator.of(dialogContext).pop(true);
                  }
                },
                child: const Text('ذخیره'),
              ),
            ],
          ),
        );
      },
    );

    if (saved == true && context.mounted) {
      await provider.saveProfile(
        senderTitle: senderController.text,
        orgTitle: orgController.text,
      );
    }

    senderController.dispose();
    orgController.dispose();
  }

  Future<void> _copyMessage(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('پیام در کلیپ‌بورد کپی شد.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MessageBuilderProvider>(
      builder: (context, provider, _) {
        if (!provider.isInitialized) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final generatedMessage = provider.generatedMessage;
        final sessionLink = provider.selectedSessionLink;
        final hasValidLink =
            sessionLink != null && sessionLink.trim().isNotEmpty;

        return Scaffold(
          appBar: AppBar(
            title: const Text('سازنده پیام دوره‌ها'),
            actions: [
              IconButton(
                tooltip: 'ویرایش مشخصات ثابت',
                onPressed: () => _openProfileDialog(context, provider),
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (provider.errorMessage != null) ...[
                Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: ListTile(
                    leading: Icon(
                      Icons.error_outline,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                    title: Text(
                      provider.errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                    trailing: IconButton(
                      onPressed: provider.clearError,
                      icon: const Icon(Icons.close),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              _ProfileBannerCard(
                hasProfile: provider.hasProfile,
                senderTitle: provider.senderTitle,
                orgTitle: provider.orgTitle,
                onEdit: () => _openProfileDialog(context, provider),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '۱. انتخاب نوع دوره',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<CourseType>(
                        value: provider.selectedCourse,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        items: CourseType.values.map((course) {
                          final totalFa = MessageGenerator.toPersianDigits(
                            course.spec.totalSessions,
                          );
                          return DropdownMenuItem<CourseType>(
                            value: course,
                            child: Text('${course.spec.title} ($totalFa جلسه)'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            provider.selectCourse(value);
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '۲. انتخاب شماره جلسه (کل جلسات: ${MessageGenerator.toPersianDigits(provider.totalSessionsInSelectedCourse)})',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List.generate(
                          provider.totalSessionsInSelectedCourse,
                          (index) {
                            final sessionNum = index + 1;
                            final isSelected =
                                provider.selectedSession == sessionNum;
                            final isLast =
                                sessionNum ==
                                provider.totalSessionsInSelectedCourse;
                            final labelFa = MessageGenerator.toPersianDigits(
                              sessionNum,
                            );
                            final chipText = isLast
                                ? 'جلسه $labelFa (آخر)'
                                : 'جلسه $labelFa';

                            return ChoiceChip(
                              label: Text(chipText),
                              selected: isSelected,
                              onSelected: (_) =>
                                  provider.selectSession(sessionNum),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'لینک خودکار جلسه ${MessageGenerator.toPersianDigits(provider.selectedSession)}:',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              hasValidLink
                                  ? sessionLink
                                  : 'لینک این جلسه هنوز ثبت نشده است.',
                              style: TextStyle(
                                color: hasValidLink
                                    ? null
                                    : Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '۳. پیام آماده ارسال',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          TextButton.icon(
                            onPressed: provider.rerollQuote,
                            icon: const Icon(Icons.refresh),
                            label: const Text('تغییر جمله قصار'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                        child: SelectableText(
                          generatedMessage ??
                              (!provider.hasProfile
                                  ? 'ابتدا عنوان ثابت و نام مجموعه را تنظیم کنید تا پیام ساخته شود.'
                                  : 'امکان ساخت پیام وجود ندارد؛ لینک جلسه را بررسی کنید.'),
                          style: const TextStyle(height: 1.7, fontSize: 15),
                        ),
                      ),
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        onPressed: generatedMessage == null
                            ? null
                            : () => _copyMessage(context, generatedMessage),
                        icon: const Icon(Icons.copy_all_outlined),
                        label: const Text('کپی پیام'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileBannerCard extends StatelessWidget {
  const _ProfileBannerCard({
    required this.hasProfile,
    required this.senderTitle,
    required this.orgTitle,
    required this.onEdit,
  });

  final bool hasProfile;
  final String senderTitle;
  final String orgTitle;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      color: hasProfile ? scheme.secondaryContainer : scheme.tertiaryContainer,
      child: ListTile(
        leading: Icon(
          hasProfile ? Icons.badge_outlined : Icons.warning_amber_rounded,
          color: hasProfile
              ? scheme.onSecondaryContainer
              : scheme.onTertiaryContainer,
        ),
        title: Text(
          hasProfile
              ? '$senderTitle-$orgTitle'
              : 'مشخصات ثابت هنوز ثبت نشده است',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: hasProfile
                ? scheme.onSecondaryContainer
                : scheme.onTertiaryContainer,
          ),
        ),
        subtitle: Text(
          hasProfile
              ? 'این اطلاعات به‌صورت خودکار در ابتدای همه پیام‌ها می‌آید.'
              : 'برای ساخت پیام، روی دکمه تنظیم بزنید.',
          style: TextStyle(
            color: hasProfile
                ? scheme.onSecondaryContainer
                : scheme.onTertiaryContainer,
          ),
        ),
        trailing: TextButton(
          onPressed: onEdit,
          child: Text(hasProfile ? 'ویرایش' : 'تنظیم'),
        ),
      ),
    );
  }
}
