import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const Color figmaBrown1 = Color(0xFF6D4C41);
const Color figmaNudeBG = Color(0xFFFDF6F0);

class AdminServicesPage extends StatefulWidget {
  const AdminServicesPage({super.key});

  @override
  State<AdminServicesPage> createState() => _AdminServicesPageState();
}

class _AdminServicesPageState extends State<AdminServicesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> categories = ["Hair", "Beauty", "Body", "Massage"];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: categories.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {}); // Update FAB label on swipe
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- CRUD ACTIONS ---
  void _showServiceDialog({
    String? docId,
    Map<String, dynamic>? data,
    required String category,
  }) {
    final nameController = TextEditingController(text: data?['name'] ?? '');
    final priceController = TextEditingController(text: data?['price'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          docId == null ? "Add $category Service" : "Edit $category Service",
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Service Name"),
              textCapitalization: TextCapitalization.words,
            ),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(
                labelText: "Price (e.g., RM25)",
              ),
              keyboardType: TextInputType.text,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: figmaBrown1),
            onPressed: () => _saveService(
              context,
              docId,
              nameController.text.trim(),
              priceController.text.trim(),
              category,
            ),
            child: const Text("Save", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _saveService(
    BuildContext ctx,
    String? docId,
    String name,
    String price,
    String category,
  ) async {
    if (name.isEmpty || price.isEmpty) return;

    final serviceData = {'name': name, 'price': price, 'category': category};

    try {
      if (docId == null) {
        await FirebaseFirestore.instance
            .collection('services')
            .add(serviceData);
      } else {
        await FirebaseFirestore.instance
            .collection('services')
            .doc(docId)
            .update(serviceData);
      }
      if (mounted) Navigator.pop(ctx);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _deleteService(String docId) {
    FirebaseFirestore.instance.collection('services').doc(docId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: figmaNudeBG,
      appBar: AppBar(
        title: const Text("Manage Services"),
        backgroundColor: figmaBrown1,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          // --- PILL SHAPED TAB BAR ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 45,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(25.0),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(25.0),
                  color: figmaBrown1,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey[600],
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                tabs: categories.map((c) => Tab(text: c)).toList(),
              ),
            ),
          ),
          const SizedBox(height: 15),

          // --- TAB CONTENT ---
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: categories
                  .map((cat) => _buildServiceList(cat))
                  .toList(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: figmaBrown1,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          "Add ${categories[_tabController.index]}",
          style: const TextStyle(color: Colors.white),
        ),
        onPressed: () {
          _showServiceDialog(category: categories[_tabController.index]);
        },
      ),
    );
  }

  Widget _buildServiceList(String category) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('services')
          .where('category', isEqualTo: category)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text("No $category services yet."));
        }

        final docs = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;

            return ServiceCard(
              name: data['name'] ?? '',
              price: data['price'] ?? '',
              onEdit: () => _showServiceDialog(
                docId: doc.id,
                data: data,
                category: category,
              ),
              onDelete: () => _deleteService(doc.id),
            );
          },
        );
      },
    );
  }
}

// --- EXTRACTED WIDGET FOR BETTER PERFORMANCE ---
class ServiceCard extends StatelessWidget {
  final String name;
  final String price;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ServiceCard({
    super.key,
    required this.name,
    required this.price,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: figmaBrown1,
          ),
        ),
        subtitle: Text(
          price,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
