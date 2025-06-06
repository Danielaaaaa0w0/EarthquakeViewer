// 檔案: lib/disaster_info_page.dart
// (新增檔案)
import 'package:flutter/material.dart';

class DisasterInfoPage extends StatelessWidget {
  const DisasterInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DefaultTabController(
      length: 2, // 有兩個分頁: SOP 和 避難包
      child: Scaffold(
        appBar: AppBar(
          title: const Text('地震防災須知'),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          bottom: TabBar(
            labelColor: theme.colorScheme.onPrimary, // 選中分頁的文字顏色
            unselectedLabelColor: theme.colorScheme.onPrimary.withOpacity(0.7), // 未選中分頁的文字顏色
            indicatorColor: theme.colorScheme.onPrimary, // 指示線顏色
            tabs: const [
              Tab(text: '地震應對SOP'),
              Tab(text: '緊急避難包'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildSopPage(context),
            _buildKitPage(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSopPage(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Text('地震發生時 - 室內SOP', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _buildInfoItem(context, Icons.arrow_downward, '趴下 (Drop)', '壓低身體，躲到堅固的桌子底下，或靠著堅固的牆壁。', textTheme),
        _buildInfoItem(context, Icons.shield_outlined, '掩護 (Cover)', '保護頭部和頸部，避免被掉落物砸傷。', textTheme),
        _buildInfoItem(context, Icons.anchor_outlined, '穩住 (Hold on)', '抓住桌腳或穩固物體，直到搖晃停止。', textTheme),
        const Divider(height: 30),
        Text('地震發生時 - 室外注意事項', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _buildInfoItem(context, Icons.landscape_outlined, '遠離建築物', '注意掉落物、招牌、磁磚等，盡快到空曠處避難。', textTheme),
        _buildInfoItem(context, Icons.electric_bolt_outlined, '遠離電線桿', '避免被電線或倒塌的電線桿波及。', textTheme),
        const Divider(height: 30),
        Text('地震之後的注意事項', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _buildInfoItem(context, Icons.healing_outlined, '檢查自身與他人是否受傷', '若有需要，進行必要的急救或尋求協助。', textTheme),
        _buildInfoItem(context, Icons.house_siding_outlined, '檢查房屋結構', '注意牆壁、樑柱是否有裂縫，若有疑慮應盡快離開。', textTheme),
        _buildInfoItem(context, Icons.warning_amber_rounded, '注意餘震', '主震後可能會有多次餘震，保持警覺。', textTheme),
        _buildInfoItem(context, Icons.speaker_phone_outlined, '收聽正確資訊', '透過官方管道獲取最新災情與指示，勿輕信謠言。', textTheme),
        _buildInfoItem(context, Icons.local_gas_station_outlined, '檢查瓦斯、水電管線', '若有損壞或異味，立即關閉總開關並通報。', textTheme),
      ],
    );
  }

  Widget _buildKitPage(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Text('緊急避難包建議物品', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _buildInfoItem(context, Icons.water_drop_outlined, '飲用水', '每人每日約需3公升，準備至少3日份。', textTheme),
        _buildInfoItem(context, Icons.fastfood_outlined, '乾糧/口糧', '選擇不需烹煮、可長期保存的食物，如餅乾、罐頭、巧克力等。', textTheme),
        _buildInfoItem(context, Icons.medical_services_outlined, '急救藥品', '常用藥品、外傷藥品、紗布、OK繃、優碘等。', textTheme),
        _buildInfoItem(context, Icons.flashlight_on_outlined, '手電筒與備用電池', '確保照明。', textTheme),
        _buildInfoItem(context, Icons.radio_outlined, '收音機與備用電池', '獲取外界資訊。', textTheme),
        _buildInfoItem(context, Icons.smartphone_outlined, '行動電源與充電線', '保持通訊。', textTheme),
        _buildInfoItem(context, Icons.attach_money_outlined, '少量現金與證件影本', '備不時之需。', textTheme),
        _buildInfoItem(context, Icons.dry_cleaning_outlined, '保暖衣物/雨具', '禦寒、防雨。', textTheme),
        _buildInfoItem(context, Icons.masks_outlined, '口罩', '防疫或防止吸入粉塵。', textTheme),
        _buildInfoItem(context, Icons.work_outline, '粗棉手套', '搬運或清除障礙物時保護雙手。', textTheme),
        _buildInfoItem(context, Icons.campaign_outlined, '哨子', '求救時使用。', textTheme),
        _buildInfoItem(context, Icons.backpack_outlined, '輕便背包', '將以上物品放入背包中，方便攜帶。', textTheme),
        const SizedBox(height: 16),
        Text('提醒：應定期檢查避難包內物品的有效期限並更新。', style: textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic)),
      ],
    );
  }

  Widget _buildInfoItem(BuildContext context, IconData icon, String title, String description, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 30.0, color: Theme.of(context).colorScheme.primary), // 使用主題顏色
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2.0),
                Text(description, style: textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}