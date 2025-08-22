import 'package:fl_clash/common/color.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:flutter/material.dart';

class CommonChip extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final ChipType type;
  final Widget? avatar;

  const CommonChip({
    super.key,
    required this.label,
    this.onPressed,
    this.avatar,
    this.type = ChipType.action,
  });

  @override
  Widget build(BuildContext context) {
    // 获取主题色
    final primaryColor = Theme.of(context).colorScheme.primary;

    if (type == ChipType.delete) {
      return Chip(
        avatar: avatar,
        labelPadding: const EdgeInsets.symmetric(
          vertical: 0,
          horizontal: 4,
        ),
        clipBehavior: Clip.antiAlias,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        onDeleted: onPressed ?? () {},
        side: BorderSide(color: Theme.of(context).dividerColor.opacity15),
        labelStyle: Theme.of(context).textTheme.bodyMedium,
        label: Text(label),
        // 自定义删除图标并设置颜色为主题色
        deleteIcon: Icon(
          Icons.cancel,
          color: primaryColor,
         // size: 18, // 可选：调整图标大小
        ),
      );
    }
    return ActionChip(
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      avatar: avatar,
      clipBehavior: Clip.antiAlias,
      labelPadding: const EdgeInsets.symmetric(
        vertical: 0,
        horizontal: 4,
      ),
      onPressed: onPressed ?? () {},
      side: BorderSide(color: Theme.of(context).dividerColor.opacity15),
      labelStyle: Theme.of(context).textTheme.bodyMedium,
      label: Text(label),
    );
  }
}
