using CRProjectEditor.ViewModels;
using System.Windows;

namespace CRProjectEditor.Views
{
    public partial class NpcEditView : Window
    {
        public NpcEditView()
        {
            InitializeComponent();
        }

        // Это свойство можно установить из NPCsViewModel перед вызовом ShowDialog()
        public NpcEditViewModel? ViewModel => DataContext as NpcEditViewModel;

        // Если мы используем CloseAction в ViewModel для закрытия окна:
        // Потребуется установить DataContext до вызова ShowDialog, а затем установить CloseAction.
        // Пример:
        // var editView = new NpcEditView();
        // var viewModel = new NpcEditViewModel(npcCopy, ...);
        // editView.DataContext = viewModel;
        // viewModel.CloseAction = (result) => { editView.DialogResult = result; editView.Close(); };
        // editView.ShowDialog();
    }
} 